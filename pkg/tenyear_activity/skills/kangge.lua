local kangge = fk.CreateSkill {
  name = "kangge"
}

Fk:loadTranslationTable{
  ['kangge'] = '抗歌',
  ['#kangge-choose'] = '抗歌：请选择“抗歌”角色',
  ['@kangge'] = '抗歌',
  ['#kangge-recover'] = '抗歌：你可以令 %dest 将体力回复至1点',
  [':kangge'] = '你的第一个回合开始时，你选择一名其他角色：<br>1.当该角色于其回合外获得手牌后，你摸等量的牌（每回合最多摸三张）；<br>2.每轮限一次，当该角色进入濒死状态时，你可以令其将体力回复至1点；<br>3.当该角色死亡时，你弃置所有牌并失去1点体力。',
  ['$kangge1'] = '慷慨悲歌，以抗凶逆。',
  ['$kangge2'] = '忧惶昼夜，抗之以歌。',
}

-- 主技能效果
kangge:addEffect({fk.TurnStart, fk.AfterCardsMove, fk.Death}, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(kangge.name) then
      if event == fk.TurnStart then
        if player ~= target then return false end
        local room = player.room
        local turn_event = room.logic:getCurrentEvent()
        if not turn_event then return false end
        local x = player:getMark("kangge_record")
        if x == 0 then
          local events = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
          for _, e in ipairs(events) do
            local current_player = e.data[1]
            if current_player == player then
              x = e.id
              room:setPlayerMark(player, "kangge_record", x)
              break
            end
          end
        end
        return turn_event.id == x
      elseif event == fk.AfterCardsMove then
        local kangge_id = player:getMark(kangge.name)
        if kangge_id ~= 0 and player:getMark("kangge-turn") < 3 then
          local kangge_player = room:getPlayerById(kangge_id)
          if kangge_player.dead or kangge_player.phase ~= Player.NotActive then return false end
          for _, move in ipairs(target) do
            if kangge_id == move.to and move.toArea == Card.PlayerHand then
              return true
            end
          end
        end
      elseif event == fk.Death then
        return player:getMark(kangge.name) == target.id
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(kangge.name)
    if event == fk.TurnStart then
      room:notifySkillInvoked(player, kangge.name, "special")
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        prompt = "#kangge-choose",
        skill_name = kangge.name,
        cancelable = false,
        no_indicate = true
      })
      if #to > 0 then
        room:setPlayerMark(player, kangge.name, to[1].id)
      end
    elseif event == fk.AfterCardsMove then
      local n = 0
      local kangge_id = player:getMark(kangge.name)
      for _, move in ipairs(target) do
        if move.to and kangge_id == move.to.id and move.toArea == Card.PlayerHand then
          n = n + #move.moveInfo
        end
      end
      if n > 0 then
        room:notifySkillInvoked(player, kangge.name, "drawcard")
        local x = math.min(n, 3 - player:getMark("kangge-turn"))
        room:addPlayerMark(player, "kangge-turn", x)
        if player:getMark("@kangge") == 0 then
          room:setPlayerMark(player, "@kangge", room:getPlayerById(kangge_id).general)
        end
        player:drawCards(x, kangge.name)
      end
    elseif event == fk.Death then
      room:notifySkillInvoked(player, kangge.name, "negative")
      if player:getMark("@kangge") == 0 then
        room:setPlayerMark(player, "@kangge", target.general)
      end
      player:throwAllCards("he")
      if not player.dead then
        room:loseHp(player, 1, kangge.name)
      end
    end
  end,
})

-- 刷新效果
kangge:addEffect({fk.BuryVictim}, {
  can_refresh = function(self, event, target, player)
    return player:getMark(kangge.name) == target.id
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, kangge.name, 0)
    room:setPlayerMark(player, "@kangge", 0)
  end,
})

-- 子技能触发效果
local kangge_trigger = fk.CreateTriggerSkill {
  name = "#kangge_trigger",
  mute = true,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player)
    return player:hasSkill(kangge) and player:getMark("kangge") == target.id and player:usedSkillTimes(kangge.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player)
    return room:askToSkillInvoke(player, {
      skill_name = "kangge",
      prompt = "#kangge-recover::" .. target.id
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke("kangge")
    room:notifySkillInvoked(player, "kangge", "support")
    room:doIndicate(player.id, {target.id})
    if player:getMark("@kangge") == 0 then
      room:setPlayerMark(player, "@kangge", target.general)
    end
    room:recover({
      who = target,
      num = 1 - target.hp,
      recoverBy = player,
      skillName = "kangge"
    })
  end,
}

return kangge
