local fazhu_active = fk.CreateSkill {
  name = "fazhu_active"
}

Fk:loadTranslationTable{
  ['fazhu_active'] = '筏铸',
}

fazhu_active:addEffect('active', {
  mute = true,
  min_card_num = 1,
  target_num = 0,
  expand_pile = function(self, player)
    return player:getTableMark(fazhu_active.name)
  end,
  card_filter = function(self, player, to_select, selected)
    return not Fk:getCardById(to_select).is_damage_card
  end,
})

return fazhu_active
