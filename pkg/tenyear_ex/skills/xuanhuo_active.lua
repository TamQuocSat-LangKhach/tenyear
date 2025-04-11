local xuanhuo_active = fk.CreateSkill {
  name = "ty_ex__xuanhuo_active",
}

Fk:loadTranslationTable{
  ["ty_ex__xuanhuo_active"] = "眩惑",
}

xuanhuo_active:addEffect("active", {
  card_num = 2,
  target_num = 2,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return to_select ~= player and #selected < 2 and #selected_cards == 2
  end,
})

return xuanhuo_active
