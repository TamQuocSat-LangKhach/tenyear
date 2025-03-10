local shuojian = fk.CreateSkill {
  name = "shuojian"
}

Fk:loadTranslationTable{
  ['shuojian_viewas'] = '数荐',
  ['shuojian'] = '数荐',
}

shuojian:addEffect('viewas', {
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("dismantlement")
    card.skillName = shuojian.name
    return card
  end,
})

return shuojian
