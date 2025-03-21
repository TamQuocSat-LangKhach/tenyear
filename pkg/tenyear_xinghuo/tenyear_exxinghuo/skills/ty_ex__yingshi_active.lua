local ty_ex__yingshi_active = fk.CreateSkill {
  name = "ty_ex__yingshi_active"
}

Fk:loadTranslationTable {
  ['ty_ex__yingshi_active'] = '应势',
}

ty_ex__yingshi_active:addEffect('active', {
  card_num = 1,
  target_num = 2,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return to_select ~= player.id
    elseif #selected == 1 then
      return true
    else
      return false
    end
  end,
})

return ty_ex__yingshi_active
