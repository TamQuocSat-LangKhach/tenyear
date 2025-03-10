local ty__juanxia = fk.CreateSkill {
  name = "ty__juanxia"
}

Fk:loadTranslationTable{
  ['ty__juanxia_active'] = '狷狭',
  ['ty__juanxia'] = '狷狭',
}

ty__juanxia:addEffect('active', {
  expand_pile = function(skill)
    return skill.ty__juanxia_names or {}
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(skill.ty__juanxia_names or {}, to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards, _, _)
    if #selected_cards == 0 then return false end
    local to = skill.ty__juanxia_target
    if #selected == 0 then
      return to_select == to
    elseif #selected == 1 then
      local card = Fk:cloneCard(Fk:getCardById(selected_cards[1]).name)
      card.skillName = ty__juanxia.name
      if card.skill:getMinTargetNum() == 2 and selected[1] == to then
        return card.skill:targetFilter(to_select, selected, {}, card, nil, player)
      end
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards == 0 then return false end
    local to_use = Fk:cloneCard(Fk:getCardById(selected_cards[1]).name)
    to_use.skillName = ty__juanxia.name
    local selected_copy = table.simpleClone(selected)
    if #selected_copy == 0 then
      table.insert(selected_copy, skill.ty__juanxia_target)
    end
    return to_use.skill:feasible(selected_copy, {}, player, to_use)
  end,
})

return ty__juanxia
