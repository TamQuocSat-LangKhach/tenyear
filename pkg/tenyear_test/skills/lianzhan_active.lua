local lianzhan_active = fk.CreateSkill {
  name = "lianzhan_active",
}

Fk:loadTranslationTable{
  ["lianzhan_active"] = "连战",
  ["lianzhan_target"] = "额外指定一个目标",
  ["lianzhan_extra"] = "额外结算一次",
}

lianzhan_active:addEffect("active", {
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  interaction = function (self, player)
    local all_choices = {"lianzhan_target", "lianzhan_extra"}
    local choices = table.simpleClone(all_choices)
    if #self.exclusive_targets == 0 then
      table.remove(choices, 1)
    end
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if self.interaction.data == "lianzhan_target" then
      return #selected == 0 and table.contains(self.exclusive_targets, to_select.id)
    else
      return false
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if self.interaction.data == "lianzhan_target" then
      return #selected == 1
    else
      return #selected == 0
    end
  end,
})

return lianzhan_active
