local wencan = fk.CreateSkill {
  name = "wencan"
}

Fk:loadTranslationTable{
  ['wencan_active'] = '文灿',
  ['wencan'] = '文灿',
}

wencan:addEffect('active', {
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
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, wencan.name, player, player)
  end,
})

return wencan
