local ty__lirang = fk.CreateSkill {
  name = "ty__lirang"
}

Fk:loadTranslationTable{
  ['ty__lirang'] = '礼让',
  ['#ty__lirang-give'] = '礼让：你可以将这些牌分配给任意角色，点“取消”仍弃置',
  [':ty__lirang'] = '当你的牌因弃置而移至弃牌堆后，你可将其中的至少一张牌交给其他角色。',
  ['$ty__lirang1'] = '夫礼先王以承天之道，以治人之情。',
  ['$ty__lirang2'] = '谦者，德之柄也，让者，礼之逐也。',
}

ty__lirang:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(ty__lirang) or player.room:getOtherPlayers(player, false) == 0 then return false end
    local cards = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end
    cards = table.filter(cards, function(id) return player.room:getCardArea(id) == Card.DiscardPile end)
    cards = U.moveCardsHoldingAreaCheck(player.room, cards)
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    local move = room:askToYiji(player, {
      cards = cards,
      targets = room:getOtherPlayers(player, false),
      skill_name = ty__lirang.name,
      min_num = 0,
      max_num = #cards,
      prompt = "#ty__lirang-give",
      expand_pile = cards,
      skip = true
    })
    local check
    for _, cds in pairs(move) do
      if #cds > 0 then
        check = true
        break
      end
    end
    if check then
      event:setCostData(self, move)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doYiji(event:getCostData(self), player.id, ty__lirang.name)
  end,
})

return ty__lirang
