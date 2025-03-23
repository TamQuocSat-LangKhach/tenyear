local silun_active = fk.CreateSkill {
  name = "silun_active"
}

Fk:loadTranslationTable {
  ['silun_active'] = '四论',
  ['Field'] = '场上',
}

silun_active:addEffect('active', {
  mute = true,
  card_num = 1,
  max_target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"Field", "Top", "Bottom"}}
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      if skill.interaction.data == "Field" then
        local card = Fk:getCardById(to_select)
        return card.type == Card.TypeEquip or card.sub_type == Card.SubtypeDelayedTrick
      end
      return true
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and skill.interaction.data == "Field" and #selected_cards == 1 then
      local card = Fk:getCardById(selected_cards[1])
      local target = Fk:currentRoom():getPlayerById(to_select)
      if card.type == Card.TypeEquip then
        return target:hasEmptyEquipSlot(card.sub_type)
      elseif card.sub_type == Card.SubtypeDelayedTrick then
        return not target:isProhibited(target, card)
      end
    end
    return false
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards == 1 then
      if skill.interaction.data == "Field" then
        return #selected == 1
      else
        return true
      end
    end
  end,
})

return silun_active
