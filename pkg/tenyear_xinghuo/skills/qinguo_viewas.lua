local qinguo = fk.CreateSkill {
  name = "qinguo"
}

Fk:loadTranslationTable{
  ['qinguo_viewas'] = '勤国',
  ['qinguo'] = '勤国',
}

qinguo:addEffect('viewas', {
  pattern = "slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = qinguo.name
    return card
  end,
})

return qinguo
