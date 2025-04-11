local ty_ex__zongxuan = fk.CreateSkill {
  name = "ty_ex__zongxuan"
}

Fk:loadTranslationTable{
  ['ty_ex__zongx__zongxuan'] = '纵玄',
  ['#ty_ex__zongxuan-choose'] = '纵玄：可以令一名其他角色获得其中一张锦囊牌',
  ['#ty_ex__zongxuan-invoke'] = '纵玄：将其中至少一张牌置于牌堆顶',
  [':ty_ex__zongxuan'] = '当你的牌因弃置而置入弃牌堆时，若其中有锦囊牌，你可以令一名其他角色获得其中一张锦囊牌，然后你可以将其余的牌中任意张置于牌堆顶。',
  ['$ty_ex__zongxuan1'] = '天命所定，乃天数之法。',
  ['$ty_ex__zongxuan2'] = '因果循坏，已有定数。',
}

ty_ex__zongxuan:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty_ex__zongxuan.name) then
      local cards = {}
      local room = player.room
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      cards = U.moveCardsHoldingAreaCheck(room, cards)
      if #cards > 0 then
        event:setCostData(self, cards)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(self))
    local trick = table.filter(cards, function (id)
      return Fk:getCardById(id).type == Card.TypeTrick
    end)
    if #trick > 0 then
      room:askToYiji(player, {
        cards = trick,
        targets = room:getOtherPlayers(player, false),
        skill_name = ty_ex__zongxuan.name,
        min_num = 0,
        max_num = 1,
        prompt = "#ty_ex__zongxuan-choose",
        expand_pile = trick,
        skip = true
      })
      if player.dead then return false end
      cards = U.moveCardsHoldingAreaCheck(room, table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end))
      if #cards == 0 then return false end
    end
    local top = room:askToArrangeCards(player, {
      skill_name = ty_ex__zongxuan.name,
      card_map = {cards, "pile_discard", "Top"},
      prompt = "#ty_ex__zongxuan-invoke",
      free_arrange = true,
      box_size = 7
    })[2]
    top = table.reverse(top)
    room:sendLog{
      type = "#PutKnownCardtoDrawPile",
      from = player.id,
      card = top
    }
    room:moveCards({
      ids = top,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = ty_ex__zongxuan.name,
      proposer = player.id,
      moveVisible = true,
    })
  end,
})

return ty_ex__zongxuan
