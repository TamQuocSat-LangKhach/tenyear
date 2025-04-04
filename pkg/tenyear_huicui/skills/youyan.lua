local youyan = fk.CreateSkill {
  name = "youyan",
}

Fk:loadTranslationTable{
  ["youyan"] = "诱言",
  [":youyan"] = "你的回合内，当你的牌因使用或打出之外的方式进入弃牌堆后，你可以从牌堆中获得本次失去的牌中没有的花色的牌各一张"..
  "（出牌阶段、弃牌阶段各限一次）。",

  ["$youyan1"] = "诱言者，为人所不齿。",
  ["$youyan2"] = "诱言之弊，不可不慎。",
}

youyan:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(youyan.name) and
      (player.phase == Player.Play or player.phase == Player.Discard) and
      player:usedSkillTimes(youyan.name, Player.HistoryPhase) == 0 then
      local suits = {"spade", "club", "heart", "diamond"}
      local can_invoke = false
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResponse then
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                can_invoke = true
              end
            end
          else
            local room = player.room
            local pindian_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian, true)
            if pindian_event then
              local pindian = pindian_event.data
              if pindian.from == player then
                local cards = room:getSubcardsByRule(pindian.fromCard)
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.Processing and table.contains(cards, info.cardId) then
                    table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                    can_invoke = true
                  end
                end
              end
              for to, result in pairs(pindian.results) do
                if to == player then
                  local cards = room:getSubcardsByRule(result.toCard)
                  for _, info in ipairs(move.moveInfo) do
                    if info.fromArea == Card.Processing and table.contains(cards, info.cardId) then
                      table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                      can_invoke = true
                    end
                  end
                end
              end
            end
          end
        end
      end
      if can_invoke and #suits > 0 then
        event:setCostData(self, {choice = suits})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = event:getCostData(self).choice
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      table.removeOne(suits, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skill_name = youyan.name,
      })
    end
  end,
})

return youyan
