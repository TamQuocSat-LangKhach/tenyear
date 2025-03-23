local pandi_active = fk.CreateSkill {
  name = "pandi_active",
}

Fk:loadTranslationTable{
  ["pandi_active"] = "盻睇",
}

pandi_active:addEffect("active", {
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and table.contains(player:getHandlyIds(), to_select) then
      local from = Fk:currentRoom():getPlayerById(self.pandi)
      local card = Fk:getCardById(to_select)
      return from:canUse(card) and not from:prohibitUse(card)
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards == 1 then
      local from = Fk:currentRoom():getPlayerById(self.pandi)
      local card = Fk:getCardById(selected_cards[1])
      return card.skill:targetFilter(from, to_select, selected, {}, card, {bypass_times = true})
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards == 1 then
      local from = Fk:currentRoom():getPlayerById(self.pandi)
      local card = Fk:getCardById(selected_cards[1])
      return card.skill:feasible(from, selected, {}, card)
    end
  end,
})

return pandi_active
