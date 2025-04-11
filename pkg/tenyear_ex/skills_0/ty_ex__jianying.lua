local ty_ex__jianying = fk.CreateSkill {
  name = "ty_ex__jianying"
}

Fk:loadTranslationTable{
  ['ty_ex__jianying'] = '渐营',
  ['@ty_ex__jianying'] = '渐营',
  [':ty_ex__jianying'] = '当你使用牌时，若此牌与你使用的上一张牌点数或花色相同，你可以摸一张牌。',
  ['$ty_ex__jianying1'] = '步步为营，缓缓而进。',
  ['$ty_ex__jianying2'] = '以强击弱，何必心急？',
}

ty_ex__jianying:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(ty_ex__jianying) then return false end
    local room = player.room
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
    local last_find = false
    for i = #events, 1, -1 do
      local e = events[i]
      if e.data[1].from == player.id then
        if e.id == use_event.id then
          last_find = true
        elseif last_find then
          local last_use = e.data[1]
          return data.card:compareSuitWith(last_use.card) or data.card:compareNumberWith(last_use.card)
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, ty_ex__jianying.name)
  end,

  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return target == player and player:hasSkill(ty_ex__jianying, true)
    elseif event == fk.EventLoseSkill then
      return data == ty_ex__jianying.name
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      room:setPlayerMark(player, "@ty_ex__jianying", {data.card:getSuitString(true), data.card:getNumberStr()})
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@ty_ex__jianying", 0)
    end
  end,
})

return ty_ex__jianying
