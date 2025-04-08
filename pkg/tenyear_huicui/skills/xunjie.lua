local xunjie = fk.CreateSkill {
  name = "xunjie",
}

Fk:loadTranslationTable{
  ["xunjie"] = "殉节",
  [":xunjie"] = "每轮各限一次，每个回合结束时，若你本回合获得过手牌（摸牌阶段除外），你可以令一名角色将手牌/体力值调整至其体力值/手牌数。",

  ["#xunjie-choose"] = "殉节：你可以令一名角色将手牌/体力值调整至其体力值/手牌数",
  ["#xunjie-choice"] = "殉节：选择令 %dest 执行的一项",
  ["xunjie1"] = "手牌数调整至体力值",
  ["xunjie2"] = "体力值调整至手牌数",

  ["$xunjie1"] = "君子有节，可杀而不可辱。",
  ["$xunjie2"] = "吾受国命，城破则身死。",
}

xunjie:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xunjie.name) and
      table.find(player.room.alive_players, function(p)
        return p:getHandcardNum() ~= p.hp
      end) and
      player:usedSkillTimes(xunjie.name, Player.HistoryRound) < 2 then
      local phase_events = player.room.logic:getEventsOfScope(GameEvent.Phase, 999, function (e)
        return e.data.phase == Player.Draw
      end, Player.HistoryTurn)
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        if not table.find(phase_events, function (phase)
          return phase.id < e.id and phase.end_id > e.id
        end) then
          for _, move in ipairs(e.data) do
            if move.to == player and move.toArea == Player.Hand then
              return true
            end
          end
        end
      end, Player.HistoryTurn) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:getHandcardNum() ~= p.hp
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xunjie-choose",
      skill_name = xunjie.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choices = {}
    for i = 1, 2, 1 do
      if player:getMark("xunjie"..i.."-round") == 0 then
        table.insert(choices, "xunjie"..i)
      end
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xunjie.name,
      prompt = "#xunjie-choice::" .. to.id,
      all_choices = {"xunjie1", "xunjie2"}
    })
    room:setPlayerMark(player, choice.."-round", 1)
    local n = to:getHandcardNum() - to.hp
    if choice == "xunjie1" then
      if n > 0 then
        room:askToDiscard(to, {
          min_num = n,
          max_num = n,
          include_equip = false,
          skill_name = xunjie.name,
        })
      else
        to:drawCards(-n, xunjie.name)
      end
    else
      if n > 0 then
        room:changeHp(to, math.min(n, to:getLostHp()), nil, xunjie.name)
      else
        room:broadcastPlaySound("./audio/system/losehp")
        room:changeHp(to, n, nil, xunjie.name)
      end
    end
  end,
})

return xunjie
