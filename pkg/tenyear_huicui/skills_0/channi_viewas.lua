local channi = fk.CreateSkill {
  name = "channi",
}

Fk:loadTranslationTable{
  ['channi_viewas'] = '谗逆',
  ['channi'] = '谗逆',
}

channi:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "duel",
  card_filter = function(self, player, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and #selected < player:getMark("channi")
  end,
  view_as = function(self, player, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcards(cards)
    card.skillName = "channi"
    return card
  end,
})

return channi
