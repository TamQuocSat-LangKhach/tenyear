local saowei_viewas = fk.CreateSkill {
  name = "saowei_viewas",
}

Fk:loadTranslationTable{
  ["saowei_viewas"] = "扫围",
}

saowei_viewas:addEffect("viewas", {
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("@@aishou-inhand") > 0
  end,
  view_as = function(self, player, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcards(cards)
    card.skillName = "saowei"
    return card
  end,
})

return saowei_viewas
