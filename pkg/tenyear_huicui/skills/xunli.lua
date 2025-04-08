local xunli = fk.CreateSkill {
  name = "xunli",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xunli"] = "询疠",
  [":xunli"] = "锁定技，当黑色牌因弃置进入弃牌堆后，将之置于你的武将牌上，称为“疠”（至多9张）。出牌阶段开始时，你可以用任意张"..
  "黑色手牌交换等量的“疠”。",

  ["jiping_li"] = "疠",
  ["#xunli-exchange"] = "询疠：用黑色手牌交换等量的“疠”",

  ["$xunli1"] = "病情扑朔，容某思量。",
  ["$xunli2"] = "此疾难辨，容某细察。",
}

xunli:addEffect(fk.AfterCardsMove, {
  derived_piles = "jiping_li",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xunli.name) and #player:getPile("jiping_li") < 9 and player:getMark("lieyi_using-phase") == 0 then
      local ids = {}
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black and
              table.contains(player.room.discard_pile, info.cardId) then
              table.insert(ids, info.cardId)
            end
          end
        end
      end
      ids = player.room.logic:moveCardsHoldingAreaCheck(ids)
      if #ids > 0 then
        event:setCostData(self, {cards = ids})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local ids = event:getCostData(self).cards
    local n = 9 - #player:getPile("jiping_li")
    if n < #ids then
      ids = table.slice(ids, 1, n + 1)
    end
    player:addToPile("jiping_li", ids, true, xunli.name)
  end,
})

xunli:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  derived_piles = "jiping_li",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunli.name) and player.phase == Player.Play and
      not player:isKongcheng() and #player:getPile("jiping_li") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color == Card.Black
    end)
    local cids = room:askToArrangeCards(player, {
      skill_name = xunli.name,
      card_map = {
        "jiping_li", player:getPile("jiping_li"),
        "$Hand", cards,
      },
      prompt = "#xunli-exchange",
      cancelable = true,
    })
    room:swapCardsWithPile(player, cids[1], cids[2], xunli.name, "jiping_li")
  end,
})

return xunli
