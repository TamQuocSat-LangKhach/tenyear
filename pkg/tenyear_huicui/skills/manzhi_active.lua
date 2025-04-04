local manzhi_active = fk.CreateSkill {
  name = "manzhi_active",
}

Fk:loadTranslationTable{
  ["manzhi_active"] = "蛮智",
  ["manzhi_give"] = "令其交给你两张牌，其视为使用【杀】",
  ["manzhi_prey"] = "获得其至多两张牌，交给其等量牌",
}

manzhi_active:addEffect("active", {
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local all_choices = {"manzhi_give", "manzhi_prey"}
    local choices = table.filter(all_choices, function (str)
      return not table.contains(player:getTableMark("_manzhi-turn"), str)
    end)
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 and to_select ~= player then
      if self.interaction.data == "manzhi_give" then
        return #to_select:getCardIds("he") > 1
      else
        return not to_select:isAllNude()
      end
    end
  end,
})

return manzhi_active
