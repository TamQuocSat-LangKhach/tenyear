local baguan_viewas = fk.CreateSkill {
  name = "baguan_viewas",
}

Fk:loadTranslationTable{
  ["baguan_viewas"] = "霸关",
}

baguan_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected < self.baguan and table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards == 0 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = "baguan"
    c:addSubcards(cards)
    return c
  end,
})

return baguan_viewas
