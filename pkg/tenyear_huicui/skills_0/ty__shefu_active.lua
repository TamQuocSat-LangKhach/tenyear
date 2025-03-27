local ty__shefu = fk.CreateSkill {
  name = "ty__shefu_active"
}

Fk:loadTranslationTable{
  ['ty__shefu_active'] = '设伏',
  ['@[ty__shefu]'] = '伏兵',
}

ty__shefu:addEffect('active', {
  card_num = 1,
  target_num = 0,
  interaction = function(skill)
    local mark = skill.player:getTableMark("@[ty__shefu]")
    local all_names = U.getAllCardNames("btd", true)
    local names = table.filter(all_names, function(name)
      return table.every(mark, function(shefu_pair)
        return shefu_pair[2] ~= name
      end)
    end)
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  can_use = Util.FalseFunc,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and skill.interaction.data
  end,
})

return ty__shefu
