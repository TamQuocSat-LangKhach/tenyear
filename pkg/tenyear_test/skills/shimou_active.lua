local shimou_active = fk.CreateSkill {
  name = "shimou_active",
}

Fk:loadTranslationTable{
  ["shimou_active"] = "势谋",
}

shimou_active:addEffect("active", {
  expand_pile = function(self, player)
    return Fk:currentRoom():getBanner("shimou")
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(Fk:currentRoom():getBanner("shimou"), to_select)
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected < self.n and #selected_cards == 1 then
      local card = Fk:cloneCard(Fk:getCardById(selected_cards[1]).name)
      card.skillName = "shimou"
      local target = Fk:currentRoom():getPlayerById(self.shimou_target)
      return card.skill:modTargetFilter(target, to_select, selected, card, {bypass_distances = true, bypass_times = true})
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    return #selected_cards == 1 and #selected > 0
  end,
})

return shimou_active
