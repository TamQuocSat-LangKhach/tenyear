local miyun = fk.CreateSkill {
  name = "miyun"
}

Fk:loadTranslationTable{
  ['miyun_active'] = '密运',
  ['miyun'] = '密运',
}

miyun:addEffect('active', {
  target_num = 1,
  min_card_num = 1,
  card_filter = function(self, player, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip then return false end
    local id = player:getMark("miyun")
    return to_select == id or table.contains(selected, id)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return table.contains(selected_cards, player:getMark("miyun")) and #selected == 0 and to_select ~= player.id
  end,
})

return miyun
