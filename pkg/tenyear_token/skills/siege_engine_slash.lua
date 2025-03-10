local siege_engine_slash = fk.CreateSkill {
  name = "siege_engine_slash"
}

Fk:loadTranslationTable{
  ['siege_engine_slash'] = '大攻车',
  ['#siege_engine_skill'] = '大攻车',
}

siege_engine_slash:addEffect('viewas', {
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = "#siege_engine_skill"
    return card
  end,
})

return siege_engine_slash
