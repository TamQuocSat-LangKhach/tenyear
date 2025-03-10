local jichouw_distribution = fk.CreateSkill {
  name = "jichouw_distribution"
}

Fk:loadTranslationTable{
  ['jichouw_distribution'] = '集筹',
}

jichouw_distribution:addEffect('active', {
  target_num = 1,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player.jichouw_cards, to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and not table.contains(player.jichouw_targets, to_select)
  end,
  can_use = Util.FalseFunc,
})

return jichouw_distribution
