local jiuxian = fk.CreateSkill {
  name = "jiuxian"
}

Fk:loadTranslationTable{
  ['jiuxian'] = '酒仙',
  [':jiuxian'] = '你使用【酒】无次数限制，你可将多目标锦囊牌当【酒】使用。',
  ['$jiuxian1'] = '地若不爱酒，地应无酒泉。',
  ['$jiuxian2'] = '天若不爱酒，酒星不在天。',
}

-- ViewAsSkill
jiuxian:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "analeptic",
  card_filter = function(self, player, to_select, selected)
    local names = {"savage_assault", "archery_attack", "amazing_grace", "god_salvation", "iron_chain", "redistribute"}
    return #selected == 0 and table.contains(names, Fk:getCardById(to_select).trueName)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local card = Fk:cloneCard("analeptic")
    card:addSubcard(cards[1])
    card.skillName = jiuxian.name
    return card
  end,
})

-- TargetModSkill
jiuxian:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card)
    return card and player:hasSkill(jiuxian) and card.trueName == "analeptic" and scope == Player.HistoryTurn
  end,
})

return jiuxian
