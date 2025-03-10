local ty_ex__xuanhuo_choose = fk.CreateSkill {
  name = "ty_ex__xuanhuo_choose"
}

Fk:loadTranslationTable{
  ['ty_ex__xuanhuo_choose'] = '眩惑',
}

ty_ex__xuanhuo_choose:addEffect('active', {
  card_num = 2,
  target_num = 2,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return to_select ~= player.id and #selected < 2 and #cards == 2
  end,
})

return ty_ex__xuanhuo_choose
