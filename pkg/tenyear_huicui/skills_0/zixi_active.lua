local zixi = fk.CreateSkill {
  name = "zixi"
}

Fk:loadTranslationTable{
  ['zixi_active'] = '姊希',
  ['qiqin'] = '绮琴',
}

zixi:addEffect('active', {
  card_num = 1,
  target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"indulgence", "supply_shortage", "lightning"}}
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("qiqin") > 0
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards == 0 or #selected > 0 then return false end
    local to = Fk:currentRoom():getPlayerById(to_select)
    return not (table.contains(to.sealedSlots, Player.JudgeSlot) or to:hasDelayedTrick(skill.interaction.data))
  end,
})

return zixi
