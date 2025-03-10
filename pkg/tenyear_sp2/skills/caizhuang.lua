local caizhuang = fk.CreateSkill {
  name = "caizhuang"
}

Fk:loadTranslationTable{
  ['caizhuang'] = '彩妆',
  ['#caizhuang-active'] = '发动 彩妆，弃置任意张牌（包含的花色数：%arg）',
  [':caizhuang'] = '出牌阶段限一次，你可以弃置任意张牌，然后重复摸牌直到手牌中的花色数等同于弃牌花色数。',
  ['$caizhuang1'] = '素手调脂粉，女子自有好颜色。',
  ['$caizhuang2'] = '为悦己者容，撷彩云为妆。',
}

caizhuang:addEffect('active', {
  anim_type = "drawcard",
  prompt = function(self, player, selected_cards, selected_targets)
    local suits = {}
    local suit = Card.NoSuit
    for _, id in ipairs(selected_cards) do
      suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    return "#caizhuang-active:::" .. tostring(#suits)
  end,
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(caizhuang.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local suits = {}
    local suit = Card.NoSuit
    for _, id in ipairs(effect.cards) do
      suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    room:throwCard(effect.cards, caizhuang.name, player, player)
    local x = #suits
    if x == 0 then return end
    while true do
      player:drawCards(1, caizhuang.name)
      suits = {}
      for _, id in ipairs(player:getCardIds("h")) do
        suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(suits, suit)
        end
      end
      if #suits >= x then return end
    end
  end,
})

return caizhuang
