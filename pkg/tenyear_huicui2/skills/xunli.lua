local xunli = fk.CreateSkill {
  name = "xunli"
}

Fk:loadTranslationTable{
  ['xunli'] = '询疠',
  ['jiping_li'] = '疠',
  ['#xunli-exchange'] = '询疠：用黑色手牌交换等量的“疠”',
  [':xunli'] = '锁定技，当黑色牌因弃置进入弃牌堆后，将之置于你的武将牌上，称为“疠”（至多9张）。出牌阶段开始时，你可以用任意张黑色手牌交换等量的“疠”。',
  ['$xunli1'] = '病情扑朔，容某思量。',
  ['$xunli2'] = '此疾难辨，容某细察。',
}

xunli:addEffect(fk.AfterCardsMove, {
  derived_piles = "jiping_li",
  can_trigger = function(self, event, target, player)
    if player:hasSkill(xunli) and player:getMark("lieyi_using-phase") == 0 then
      local ids = {}
      for _, move in ipairs(target.data.moves) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black and player.room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insert(ids, info.cardId)
            end
          end
        end
      end
      if #ids > 0 and #player:getPile("jiping_li") < 9 then
        event:setCostData(self, ids)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local ids = event:getCostData(self)
    local n = 9 - #player:getPile("jiping_li")
    if n < #ids then
      ids = table.slice(ids, 1, n + 1)
    end
    player:addToPile("jiping_li", ids, true, xunli.name)
  end,
})

xunli:addEffect(fk.EventPhaseStart, {
  derived_piles = "jiping_li",
  can_trigger = function(self, event, target, player)
    if player:hasSkill(xunli) and player:getMark("lieyi_using-phase") == 0 then
      return target == player and player.phase == Player.Play and not player:isKongcheng() and #player:getPile("jiping_li") > 0
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id, true).color == Card.Black and Fk:getCardById(id).color == Card.Black
    end)

    local piles = room:askToArrangeCards(player, {
      skill_name = xunli.name,
      card_map = {player:getPile("jiping_li"), cards},
      prompt = "#xunli-exchange",
      free_arrange = true,
      area_names = {"jiping_li", "$Hand"},
    })

    U.swapCardsWithPile(player, piles[1], piles[2], xunli.name, "jiping_li", true)
  end,
})

return xunli
