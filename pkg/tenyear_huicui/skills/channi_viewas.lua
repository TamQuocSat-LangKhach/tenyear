local channi_viewas = fk.CreateSkill {
  name = "channi_viewas",
}

Fk:loadTranslationTable{
  ["channi_viewas"] = "谗逆",
}

channi_viewas:addEffect("viewas", {
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getHandlyIds(), to_select) and #selected < self.channi_num
  end,
  view_as = function(self, player, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcards(cards)
    card.skillName = "channi"
    return card
  end,
})

return channi_viewas
