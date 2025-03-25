local mingshi = fk.CreateSkill {
  name = "mingshil",
}

Fk:loadTranslationTable{
  ["mingshil"] = "明势",
  [":mingshil"] = "摸牌阶段结束时，你可以摸两张牌，然后展示三张手牌并令一名其他角色获得其中一张。",

  ["#mingshil-give"] = "明势：展示三张手牌，令一名其他角色获得其中一张",
  ["#mingshil-choose"] = "明势：获得其中一张牌",

  ["$mingshil1"] = "联刘以抗曹，此可行之大势。",
  ["$mingshil2"] = "强敌在北，唯协力可御之。",
}

mingshi:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw and player:hasSkill(mingshi.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:drawCards(2, mingshi.name)
    if player.dead or player:getHandcardNum() < 3 or #room:getOtherPlayers(player, false) == 0 then return false end
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      min_card_num = 3,
      max_card_num = 3,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|.|hand",
      prompt = "#mingshil-give",
      skill_name = mingshi.name,
      cancelable = false,
    })
    player:showCards(cards)
    cards = table.filter(cards, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
    local to = tos[1]
    if to.dead or #cards == 0 then return end
    local card = room:askToChooseCard(to, {
      target = player,
      flag = { card_data = {{ player.general, cards }} },
      skill_name = mingshi.name,
      prompt = "#mingshil-choose",
    })
    room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonPrey, mingshi.name, nil, true, to)
  end,
})

return mingshi
