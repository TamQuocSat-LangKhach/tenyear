local zhifou_active = fk.CreateSkill {
  name = "zhifou_active",
}

Fk:loadTranslationTable{
  ["zhifou_active"] = "知否",
}

zhifou_active:addEffect("active", {
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local all_choices = {"zhifou_put", "zhifou_discard", "loseHp"}
    local choices = table.filter(all_choices, function(choice)
      return not table.contains(player:getTableMark("zhifou-turn"), choice)
    end)
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
})

return zhifou_active
