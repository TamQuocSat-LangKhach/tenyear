local juanxia_active = fk.CreateSkill {
  name = "ty__juanxia_active",
}

Fk:loadTranslationTable{
  ["ty__juanxia_active"] = "狷狭",
}

juanxia_active:addEffect("active", {
  expand_pile = function(self, player)
    return self.ty__juanxia_names
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(self.ty__juanxia_names, to_select)
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected_cards == 1 then
      local card = Fk:cloneCard(Fk:getCardById(selected_cards[1]).name)
      card.skillName = "ty__juanxia"
      local target = Fk:currentRoom():getPlayerById(self.ty__juanxia_target)
      if #selected == 0 then
        return to_select == target
      else
        return card.skill:targetFilter(player, to_select, selected, {}, card, {bypass_distances = true})
      end
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards == 0 then return false end
    local card = Fk:cloneCard(Fk:getCardById(selected_cards[1]).name)
    card.skillName = "ty__juanxia"
    return card.skill:feasible(player, selected, {}, card)
  end,
})

return juanxia_active
