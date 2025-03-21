local mingshil = fk.CreateSkill {
  name = "mingshil"
}

Fk:loadTranslationTable{
  ['mingshil'] = '明势',
  ['#mingshil-give'] = '明势：展示3张手牌，令1名其他角色获得其中1张',
  ['#mingshil-choose'] = '明势：获得其中一张牌',
  [':mingshil'] = '摸牌阶段结束时，你可以摸两张牌，然后展示三张手牌并令一名其他角色获得其中一张。',
  ['$mingshil1'] = '联刘以抗曹，此可行之大势。',
  ['$mingshil2'] = '强敌在北，唯协力可御之。',
}

mingshil:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw and player:hasSkill(mingshil.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:drawCards(player, 2, mingshil.name)
    if player.dead or player:getHandcardNum() < 3 or #room.alive_players < 2 then return false end
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 3,
      max_card_num = 3,
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_target_num = 1,
      max_target_num = 1,
      pattern = ".|.|.|hand",
      prompt = "#mingshil-give",
      skill_name = "mingshil",
      cancelable = false
    })
    player:showCards(cards)
    cards = table.filter(cards, function(id) return table.contains(player:getCardIds("h"), id) end)
    local to = room:getPlayerById(tos[1])
    if to.dead or #cards == 0 then return end
    local card = room:askToChooseCards(to, {
      min_num = 1,
      max_num = 1,
      prompt = "#mingshil-choose",
      skill_name = "mingshil"
    })
    room:moveCardTo(Fk:getCardById(card[1]), Card.PlayerHand, to, fk.ReasonPrey, mingshil.name, nil, true, to.id)
  end,
})

return mingshil
