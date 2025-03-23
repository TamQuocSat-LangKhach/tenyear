local jilis = fk.CreateSkill {
  name = "jilis"
}

Fk:loadTranslationTable{
  ['jilis'] = '蒺藜',
  [':jilis'] = '当你于一回合内使用或打出第X张牌时，你可以摸X张牌（X为你的攻击范围）。',
  ['$jilis1'] = '蒺藜骨朵，威震慑敌！',
  ['$jilis2'] = '看我一招，铁蒺藜骨朵！',
}

jilis:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jilis.name) then
      local x, y = player:getAttackRange(), player:getMark("jilis_times-turn")
      if x >= y then
        local room = player.room
        local logic = room.logic
        local end_id = player:getMark("jilis_record-turn")
        local e = logic:getCurrentEvent()
        if end_id == 0 then
          local turn_event = e:findParent(GameEvent.Turn, false)
          if turn_event == nil then return false end
          end_id = turn_event.id
        end
        room:setPlayerMark(player, "jilis_record-turn", logic.current_event_id)
        local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
        for i = #events, 1, -1 do
          e = events[i]
          if e.id <= end_id then break end
          local use = e.data[1]
          if use.from == player.id then
            y = y + 1
          end
        end
        events = logic.event_recorder[GameEvent.RespondCard] or Util.DummyTable
        for i = #events, 1, -1 do
          e = events[i]
          if e.id <= end_id then break end
          local use = e.data[1]
          if use.from == player.id then
            y = y + 1
          end
        end
        room:setPlayerMark(player, "jilis_times-turn", y)
        return x == y
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getAttackRange())
  end,
})

jilis:addEffect(fk.CardResponding, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jilis.name) then
      local x, y = player:getAttackRange(), player:getMark("jilis_times-turn")
      if x >= y then
        local room = player.room
        local logic = room.logic
        local end_id = player:getMark("jilis_record-turn")
        local e = logic:getCurrentEvent()
        if end_id == 0 then
          local turn_event = e:findParent(GameEvent.Turn, false)
          if turn_event == nil then return false end
          end_id = turn_event.id
        end
        room:setPlayerMark(player, "jilis_record-turn", logic.current_event_id)
        local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
        for i = #events, 1, -1 do
          e = events[i]
          if e.id <= end_id then break end
          local use = e.data[1]
          if use.from == player.id then
            y = y + 1
          end
        end
        events = logic.event_recorder[GameEvent.RespondCard] or Util.DummyTable
        for i = #events, 1, -1 do
          e = events[i]
          if e.id <= end_id then break end
          local use = e.data[1]
          if use.from == player.id then
            y = y + 1
          end
        end
        room:setPlayerMark(player, "jilis_times-turn", y)
        return x == y
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getAttackRange())
  end,
})

return jilis
