local miyun_active = fk.CreateSkill {
  name = "miyun_active",
}

Fk:loadTranslationTable{
  ["miyun_active"] = "密运",
}

miyun_active:addEffect("active", {
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  feasible = function (self, player, selected, selected_cards, card)
    return #selected == 1 and #selected_cards > 0 and
      table.find(selected_cards, function (id)
        return Fk:getCardById(id):getMark("@@miyun_safe-inhand-round") > 0
      end)
  end,
})

return miyun_active
