local caizhuang = fk.CreateSkill {
  name = "caizhuang",
}

Fk:loadTranslationTable{
  ["caizhuang"] = "彩妆",
  [":caizhuang"] = "出牌阶段限一次，你可以弃置任意张牌，然后重复摸牌直到手牌中的花色数等同于弃牌花色数。",

  ["#caizhuang"] = "彩妆：弃置任意张牌，然后摸牌直到手牌中花色数等于弃牌花色数（已选择花色数：%arg）",

  ["$caizhuang1"] = "素手调脂粉，女子自有好颜色。",
  ["$caizhuang2"] = "为悦己者容，撷彩云为妆。",
}

caizhuang:addEffect("active", {
  anim_type = "drawcard",
  prompt = function(self, player, selected_cards)
    local suits = {}
    local suit = Card.NoSuit
    for _, id in ipairs(selected_cards) do
      suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    return "#caizhuang:::"..#suits
  end,
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(caizhuang.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local suits = {}
    for _, id in ipairs(effect.cards) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    table.removeOne(suits, Card.NoSuit)
    room:throwCard(effect.cards, caizhuang.name, player, player)
    local x = #suits
    if x == 0 then return end
    while not player.dead do
      player:drawCards(1, caizhuang.name)
      suits = {}
      for _, id in ipairs(player:getCardIds("h")) do
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
      table.removeOne(suits, Card.NoSuit)
      if #suits >= x then return end
    end
  end,
})

return caizhuang
