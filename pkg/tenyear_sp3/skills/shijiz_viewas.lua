local shijiz = fk.CreateSkill {
  name = "shijiz"
}

Fk:loadTranslationTable{
  ['shijiz_viewas'] = '十计',
  ['shijiz'] = '十计',
}

shijiz:addEffect('viewas', {
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(shijiz.name)
    card:addSubcard(cards[1])
    card.skillName = "shijiz"
    return card
  end,
})

return shijiz
