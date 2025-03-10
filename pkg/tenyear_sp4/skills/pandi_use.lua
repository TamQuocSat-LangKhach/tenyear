local pandi = fk.CreateSkill {
  name = "pandi"
}

Fk:loadTranslationTable{
  ['pandi_use'] = '盻睇',
}

pandi:addEffect('active', {
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local room = Fk:currentRoom()
    if room:getCardArea(to_select) == Card.PlayerEquip then return false end
    local target_id = player:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    local card = Fk:getCardById(to_select)
    return target:canUse(card) and not target:prohibitUse(card)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards ~= 1 then return false end
    local card = Fk:getCardById(selected_cards[1])
    local card_skill = card.skill
    local room = Fk:currentRoom()
    local target_id = player:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    if card_skill:getMinTargetNum() == 0 or #selected >= card_skill:getMaxTargetNum(target, card) then return false end
    return not target:isProhibited(room:getPlayerById(to_select), card) and
      card_skill:modTargetFilter(to_select, selected, target, card, true)
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards ~= 1 then return false end
    local card = Fk:getCardById(selected_cards[1])
    local card_skill = card.skill
    local room = Fk:currentRoom()
    local target_id = player:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    return #selected >= card_skill:getMinTargetNum() and #selected <= card_skill:getMaxTargetNum(target, card)
  end,
})

return pandi
