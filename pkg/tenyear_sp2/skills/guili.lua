local guili = fk.CreateSkill {
  name = "guili"
}

Fk:loadTranslationTable{
  ['guili'] = '归离',
  ['#guili-choose'] = '归离：选择一名角色，其回合结束时，若其本回合未造成过伤害，你执行一个额外回合',
  ['@@guili'] = '归离',
  [':guili'] = '你的第一个回合开始时，你选择一名其他角色。该角色每轮的第一个回合结束时，若其本回合未造成过伤害，你执行一个额外的回合。',
  ['$guili1'] = '既离厄海，当归泸沽。',
  ['$guili2'] = '山野如春，不如归去。',
}

guili:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(guili) then
      local room = player.room
      if target == player and event == fk.TurnStart then
        local turn_event = room.logic:getCurrentEvent()
        if not turn_event then return false end
        local x = player:getMark("guili_record")
        if x == 0 then
          local events = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
          for _, e in ipairs(events) do
            local current_player = e.data[1]
            if current_player == player then
              x = e.id
              room:setPlayerMark(player, "guili_record", x)
              break
            end
          end
        end
        return turn_event.id == x
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    if event == fk.TurnStart then
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        prompt = "#guili-choose",
        skill_name = guili.name,
        cancelable = false,
        no_indicate = true,
        targets = targets
      })
      local to
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:setPlayerMark(player, guili.name, to.id)
      room:setPlayerMark(room:getPlayerById(to.id), "@@guili", 1)
    end
  end,
})

guili:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(guili) then
      local room = player.room
      if event == fk.TurnEnd and not target.dead and player:getMark(guili.name) == target.id then
        local turn_event = room.logic:getCurrentEvent()
        if not turn_event then return false end
        local x = target:getMark("guili_record-round")
        if x == 0 then
          room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
            local current_player = e.data[1]
            if current_player == target then
              x = e.id
              room:setPlayerMark(target, "guili_record", x)
              return true
            end
          end, Player.HistoryRound)
        end
        return turn_event.id == x and #room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local damage = e.data[5]
          if damage and target == damage.from then
            return true
          end
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    if event == fk.TurnEnd then
      player:gainAnExtraTurn(true)
    end
  end,
})

return guili
