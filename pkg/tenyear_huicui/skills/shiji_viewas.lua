local shiji_viewas = fk.CreateSkill {
  name = "shijiz_viewas",
}

Fk:loadTranslationTable{
  ["shijiz_viewas"] = "十计",
}

shiji_viewas:addEffect("viewas", {
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  handly_pile = true,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(self.shijiz_name)
    card:addSubcard(cards[1])
    card.skillName = "shijiz"
    return card
  end,
})

return shiji_viewas
