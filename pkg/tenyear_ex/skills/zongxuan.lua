local zongxuan = fk.CreateSkill {
  name = "ty_ex__zongxuan",
}

Fk:loadTranslationTable{
  ["ty_ex__zongxuan"] = "纵玄",
  [":ty_ex__zongxuan"] = "当你的牌因弃置而置入弃牌堆后，若其中有锦囊牌，你可以令一名其他角色获得其中一张锦囊牌，然后你可以"..
  "将其余的牌中任意张置于牌堆顶。",

  ["#ty_ex__zongxuan-give"] = "纵玄：你可以令一名其他角色获得其中一张锦囊牌",
  ["#ty_ex__zongxuan-invoke"] = "纵玄：将其中至少一张牌置于牌堆顶",

  ["$ty_ex__zongxuan1"] = "天命所定，乃天数之法。",
  ["$ty_ex__zongxuan2"] = "因果循坏，已有定数。",
}

zongxuan:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zongxuan.name) then
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              table.contains(player.room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      cards = player.room.logic:moveCardsHoldingAreaCheck(cards)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(self).cards)
    local trick = table.filter(cards, function (id)
      return Fk:getCardById(id).type == Card.TypeTrick
    end)
    if #trick > 0 and #room:getOtherPlayers(player, false) > 0 then
      room:askToYiji(player, {
        cards = trick,
        targets = room:getOtherPlayers(player, false),
        skill_name = zongxuan.name,
        min_num = 0,
        max_num = 1,
        prompt = "#ty_ex__zongxuan-give",
        expand_pile = trick,
      })
      if player.dead then return end
    end
    cards = room.logic:moveCardsHoldingAreaCheck(table.filter(cards, function (id)
      return table.contains(room.discard_pile, id)
    end))
    if #cards == 0 then return end
    local top = room:askToArrangeCards(player, {
      skill_name = zongxuan.name,
      card_map = {
        "Top",
        "pile_discard", cards,
      },
      prompt = "#ty_ex__zongxuan-invoke",
      free_arrange = true,
      box_size = 7
    })[1]
    top = table.reverse(top)
    room:moveCards({
      ids = top,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = zongxuan.name,
      proposer = player,
      moveVisible = true,
    })
  end,
})

return zongxuan
