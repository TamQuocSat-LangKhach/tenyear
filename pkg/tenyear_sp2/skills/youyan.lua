local youyan = fk.CreateSkill {
  name = "youyan"
}

Fk:loadTranslationTable{
  ['youyan'] = '诱言',
  [':youyan'] = '你的回合内，当你的牌因使用或打出之外的方式进入弃牌堆后，你可以从牌堆中获得本次弃牌中没有的花色的牌各一张（出牌阶段、弃牌阶段各限一次）。',
  ['$youyan1'] = '诱言者，为人所不齿。',
  ['$youyan2'] = '诱言之弊，不可不慎。',
}

youyan:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(youyan) and (player.phase == Player.Play or player.phase == Player.Discard) and
      player:usedSkillTimes(youyan.name, Player.HistoryPhase) == 0 then
      local suits = {"spade", "club", "heart", "diamond"}
      local can_invoked = false
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResponse then
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                can_invoked = true
              end
            end
          else
            local room = player.room
            local parentPindianEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian, true)
            if parentPindianEvent then
              local pindianData = parentPindianEvent.data[1]
              if pindianData.from == player then
                local leftFromCardIds = room:getSubcardsByRule(pindianData.fromCard)
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.Processing and table.contains(leftFromCardIds, info.cardId) then
                    table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                    can_invoked = true
                  end
                end
              end
              for toId, result in pairs(pindianData.results) do
                if player.id == toId then
                  local leftToCardIds = room:getSubcardsByRule(result.toCard)
                  for _, info in ipairs(move.moveInfo) do
                    if info.fromArea == Card.Processing and table.contains(leftToCardIds, info.cardId) then
                      table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                      can_invoked = true
                    end
                  end
                end
              end
            end
          end
        end
      end
      if can_invoked and #suits > 0 then
        event:setCostData(self, suits)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = event:getCostData(self)
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      table.removeOne(suits, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skill_name = youyan.name,
      })
    end
  end,
})

return youyan
