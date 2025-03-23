local zongfan = fk.CreateSkill {
  name = "zongfan"
}

Fk:loadTranslationTable{
  ['zongfan_active'] = '纵反',
}

zongfan:addEffect('active', {
  min_card_num = 1,
  target_num = 1,
  card_filter = Util.TrueFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select:objectName() ~= player:objectName()
  end,
})

return zongfan
