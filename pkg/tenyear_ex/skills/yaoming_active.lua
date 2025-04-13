local yaoming_active = fk.CreateSkill {
  name = "ty_ex__yaoming_active",
}

Fk:loadTranslationTable{
  ["ty_ex__yaoming_active"] = "邀名",
  ["ty_ex__yaoming1"] = "弃置一名其他角色一张手牌",
  ["ty_ex__yaoming2"] = "令一名其他角色摸一张牌",
  ["ty_ex__yaoming3"] = "令一名角色弃置至多两张牌，摸等量的牌",
}

yaoming_active:addEffect("active", {
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local choices, all_choices = {}, {}
    for i = 1, 3 do
      table.insert(all_choices, "ty_ex__yaoming"..i)
      if not table.contains(player:getTableMark("ty_ex__yaoming-turn"), i) then
        table.insert(choices, "ty_ex__yaoming"..i)
      end
    end
    return UI.ComboBox {choices = choices, all_choices = all_choices }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      if self.interaction.data == "ty_ex__yaoming1" then
        return to_select ~= player and not to_select:isKongcheng()
      elseif self.interaction.data == "ty_ex__yaoming2" then
        return to_select ~= player
      elseif self.interaction.data == "ty_ex__yaoming3" then
        return not to_select:isNude()
      end
    end
  end,
})

return yaoming_active
