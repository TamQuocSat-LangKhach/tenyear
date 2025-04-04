local guili = fk.CreateSkill {
  name = "guili",
}

Fk:loadTranslationTable{
  ["guili"] = "归离",
  [":guili"] = "你的第一个回合开始时，你选择一名其他角色。该角色每轮的第一个回合结束时，若其本回合未造成过伤害，你执行一个额外的回合。",

  ["#guili-choose"] = "归离：选择一名角色，其回合结束时，若其本回合未造成过伤害，你执行额外回合",
  ["@@guili"] = "归离",

  ["$guili1"] = "既离厄海，当归泸沽。",
  ["$guili2"] = "山野如春，不如归去。",
}

guili:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(guili.name) and
      player:getMark(guili.name) == 0 and
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
      prompt = "#guili-choose",
      skill_name = guili.name,
      cancelable = false,
    })[1]
    room:setPlayerMark(player, guili.name, to.id)
    room:addTableMark(to, "@@guili", player.id)
  end,
})

guili:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(guili.name) and player:getMark(guili.name) == target.id and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == target
      end, Player.HistoryTurn) == 0 then
        local turn_events = player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
          return e.data.who == target
        end, Player.HistoryRound)
        return #turn_events == 1 and turn_events[1].data == data
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:gainAnExtraTurn(true)
  end,
})

guili:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, "@@guili", player.id)
  end
end)

return guili
