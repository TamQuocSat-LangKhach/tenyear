local kangge = fk.CreateSkill {
  name = "kangge",
}

Fk:loadTranslationTable{
  ["kangge"] = "抗歌",
  [":kangge"] = "你的第一个回合开始时，你选择一名其他角色：<br>"..
  "1.当该角色于其回合外获得手牌后，你摸等量的牌（每回合最多摸三张）；<br>"..
  "2.每轮限一次，当该角色进入濒死状态时，你可以令其将体力回复至1点；<br>"..
  "3.当该角色死亡时，你弃置所有牌并失去1点体力。",

  ["#kangge-choose"] = "抗歌：请选择“抗歌”角色",
  ["@kangge"] = "抗歌",
  ["#kangge-recover"] = "抗歌：你可以令 %dest 将体力回复至1点",

  ["$kangge1"] = "慷慨悲歌，以抗凶逆。",
  ["$kangge2"] = "忧惶昼夜，抗之以歌。",
}

kangge:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(kangge.name) and
      player:getMark(kangge.name) == 0 and
      #player.room:getOtherPlayers(player, false) > 0 then
      local turn_events = player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
        return e.data.who == player
      end, Player.HistoryGame)
      return #turn_events == 1 and turn_events[1].data == data
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      prompt = "#kangge-choose",
      skill_name = kangge.name,
      cancelable = false,
    })[1]
    room:setPlayerMark(player, kangge.name, to.id)
  end,
})

kangge:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(kangge.name) and player:getMark(kangge.name) ~= 0 and player:getMark("kangge_draw-turn") < 3 then
      for _, move in ipairs(data) do
        if move.to and move.to.id == player:getMark(kangge.name) and move.toArea == Card.PlayerHand and
          player.room.current ~= move.to then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, move in ipairs(data) do
      if move.to.id == player:getMark(kangge.name) and move.toArea == Card.PlayerHand then
        n = n + #move.moveInfo
        if n + player:getMark("kangge_draw-turn") > 2 then break end
      end
    end
    n = math.min(n, 3 - player:getMark("kangge-turn"))
    room:addPlayerMark(player, "kangge-turn", n)
    room:setPlayerMark(player, "@kangge", room:getPlayerById(player:getMark(kangge.name)).general)
    player:drawCards(n, kangge.name)
  end,
})

kangge:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kangge.name) and player:getMark(kangge.name) == target.id and
      player:usedEffectTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = kangge.name,
      prompt = "#kangge-recover::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@kangge", target.general)
    room:recover{
      who = target,
      num = 1 - target.hp,
      recoverBy = player,
      skillName = kangge.name,
    }
  end,
})

kangge:addEffect(fk.Death, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:getMark(kangge.name) == target.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@kangge", 0)
    player:throwAllCards("he", kangge.name)
    if not player.dead then
      room:loseHp(player, 1, kangge.name)
    end
  end,
})

return kangge
