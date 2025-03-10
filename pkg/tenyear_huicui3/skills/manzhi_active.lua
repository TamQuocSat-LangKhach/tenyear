local manzhi_active = fk.CreateSkill {
  name = "manzhi_active"
}

Fk:loadTranslationTable{
  ['manzhi_active'] = '蛮智',
  ['manzhi_give'] = '令其交给你两张牌，其视为使用【杀】',
  ['manzhi_prey'] = '获得至多两张牌，交给其等量牌并牌',
}

manzhi_active:addEffect('active', {
  card_num = 0,
  target_num = 1,
  interaction = function()
    local all_choices = {"manzhi_give", "manzhi_prey"}
    local choices = table.filter(all_choices, function (str) return not table.contains(Self:getTableMark("_manzhi-turn"), str) end)
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local to = Fk:currentRoom():getPlayerById(to_select)
    if #selected > 0 or player.id == to_select then return false end
    if skill.interaction.data == "manzhi_give" then
      return #to:getCardIds("he") > 1
    else
      return not to:isAllNude()
    end
  end,
})

return manzhi_active
