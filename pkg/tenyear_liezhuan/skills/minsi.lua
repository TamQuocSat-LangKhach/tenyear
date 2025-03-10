local minsi = fk.CreateSkill {
  name = "minsi"
}

Fk:loadTranslationTable{
  ['minsi'] = '敏思',
  ['#minsi'] = '敏思：弃置任意张点数之和为13的牌，摸两倍的牌',
  ['@@minsi-inhand-turn'] = '敏思',
  [':minsi'] = '出牌阶段限一次，你可以弃置任意张点数之和为13的牌，并摸两倍的牌。本回合以此法获得的牌中，黑色牌无距离限制，红色牌不计入手牌上限。',
  ['$minsi1'] = '能书会记，心思灵巧。',
  ['$minsi2'] = '才情兼备，选入掖庭。',
}

minsi:addEffect('active', {
  anim_type = "drawcard",
  min_card_num = 1,
  target_num = 0,
  prompt = "#minsi",
  can_use = function(self, player)
    return player:usedSkillTimes(minsi.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    if not player:prohibitDiscard(Fk:getCardById(to_select)) then
      local num = 0
      for _, id in ipairs(selected) do
        num = num + Fk:getCardById(id).number
      end
      return num + Fk:getCardById(to_select).number <= 13
    end
  end,
  feasible = function(self, player, selected_cards)
    local num = 0
    for _, id in ipairs(selected_cards) do
      num = num + Fk:getCardById(id).number
    end
    return num == 13
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:askToDiscard(player, {
      min_num = #effect.cards,
      max_num = #effect.cards,
      include_equip = false,
      pattern = "",
      skill_name = minsi.name,
      cancelable = true
    })
    if not player.dead then
      player:drawCards(2 * #effect.cards, minsi.name, nil, "@@minsi-inhand-turn")
    end
  end,
})

minsi:addEffect('targetmod', {
  bypass_distances = function(self, player, skill, card, to)
    return card and card:getMark("@@minsi-inhand-turn") > 0 and card.color == Card.Black
  end,
})

minsi:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return card:getMark("@@minsi-inhand-turn") > 0 and card.color == Card.Red
  end,
})

return minsi
