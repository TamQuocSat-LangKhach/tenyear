local hengwu = fk.CreateSkill {
  name = "hengwu"
}

Fk:loadTranslationTable{
  ['hengwu'] = '横骛',
  [':hengwu'] = '当你使用或打出牌时，若你没有该花色的手牌，你可以摸X张牌（X为场上与此牌花色相同的装备数量）。',
  ['$hengwu1'] = '横枪立马，独啸秋风！',
  ['$hengwu2'] = '世皆彳亍，唯我纵横！',
}

hengwu:addEffect(fk.CardUsing, {
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(hengwu.name) then
      local suit = data.card.suit
      return table.every(player.player_cards[Player.Hand], function (id)
        return Fk:getCardById(id).suit ~= suit end) and table.find(player.room.alive_players, function (p)
          return table.find(p.player_cards[Player.Equip], function (id)
            return Fk:getCardById(id).suit == suit end) end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local x = 0
    local suit = data.card.suit
    for _, p in ipairs(player.room.alive_players) do
      for _, id in ipairs(p.player_cards[Player.Equip]) do
        if Fk:getCardById(id).suit == suit then
          x = x + 1
        end
      end
    end
    if x > 0 then
      player:drawCards(x, hengwu.name)
    end
  end,
})

return hengwu
