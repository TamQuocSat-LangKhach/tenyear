local qinshen = fk.CreateSkill {
  name = "qinshen",
}

Fk:loadTranslationTable{
  ["qinshen"] = "勤慎",
  [":qinshen"] = "弃牌阶段结束时，你可以摸X张牌（X为本回合没有进入过弃牌堆的花色数量）。",

  ["$qinshen1"] = "怀藏拙之心，赚不名之利。",
  ["$qinshen2"] = "勤可补拙，慎可避祸。",
}

qinshen:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(qinshen.name) and player.phase == Player.Discard then
      local suits = {1, 2, 3, 4}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.removeOne(suits, Fk:getCardById(info.cardId).suit)
            end
          end
        end
        return #suits == 0
      end, Player.HistoryTurn)
      if #suits > 0 then
        event:setCostData(self, {choice = #suits})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self).choice, qinshen.name)
  end,
})

return qinshen
