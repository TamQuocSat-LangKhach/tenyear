local wencan_active = fk.CreateSkill {
  name = "wencan_active"
}

Fk:loadTranslationTable{
  ["wencan_active"] = "文灿",
}

wencan_active:addEffect("active", {
  mute = true,
  card_num = 2,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    if not player:prohibitDiscard(card) and card.suit ~= Card.NoSuit then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return card.suit ~= Fk:getCardById(selected[1]).suit
      else
        return false
      end
    end
  end,
})

return wencan_active
