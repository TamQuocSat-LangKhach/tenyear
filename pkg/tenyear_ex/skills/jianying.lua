local jianying = fk.CreateSkill {
  name = "ty_ex__jianying",
}

Fk:loadTranslationTable{
  ["ty_ex__jianying"] = "渐营",
  [":ty_ex__jianying"] = "当你使用牌时，若此牌与你使用的上一张牌点数或花色相同，你可以摸一张牌。",

  ["@ty_ex__jianying"] = "渐营",

  ["$ty_ex__jianying1"] = "步步为营，缓缓而进。",
  ["$ty_ex__jianying2"] = "以强击弱，何必心急？",
}

jianying:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jianying.name) then
      local use_event = player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.id < player.room.logic:getCurrentEvent().id then
          return e.data.from == player
        end
      end, 1)
      if #use_event == 1 then
        local use = use_event[1].data
        return (use.card.number == data.card.number and data.card.number > 0) or use.card:compareSuitWith(data.card)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jianying.name)
  end,
})

jianying:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(jianying.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty_ex__jianying", {data.card:getSuitString(true), data.card:getNumberStr()})
  end,
})

jianying:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@ty_ex__jianying", 0)
end)

return jianying
