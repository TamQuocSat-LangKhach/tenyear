local huagui_active = fk.CreateSkill {
  name = "huagui_active",
}

Fk:loadTranslationTable{
  ["huagui_active"] = "化归",
}

huagui_active:addEffect("active", {
  card_num = 1,
  target_num = 0,
  interaction = UI.ComboBox { choices = {"show", "give"} },
  card_filter = function (self, player, to_select, selected)
    return #selected == 0
  end,
})

return huagui_active
