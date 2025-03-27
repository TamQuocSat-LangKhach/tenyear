local zhifou = fk.CreateSkill {
  name = "zhifou_active"
}

Fk:loadTranslationTable{
  ['zhifou_active'] = '知否',
  ['zhifou_put'] = '将一张牌置入“翼”',
  ['zhifou_discard'] = '弃置两张牌',
  ['zhifou_losehp'] = '失去1点体力',
}

zhifou:addEffect('active', {
  card_num = 0,
  target_num = 1,
  interaction = function()
    local all_choices = {"zhifou_put", "zhifou_discard", "zhifou_losehp"}
    local choices = table.filter(all_choices, function(choice)
      return not table.contains(Self:getTableMark("zhifou-turn"), choice)
    end)
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
})

return zhifou
