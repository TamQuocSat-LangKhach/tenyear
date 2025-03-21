local qinshen = fk.CreateSkill {
  name = "qinshen"
}

Fk:loadTranslationTable{
  ['qinshen'] = '勤慎',
  ['#qinshen-invoke'] = '勤慎：你可以摸%arg张牌',
  [':qinshen'] = '弃牌阶段结束时，你可摸X张牌（X为本回合没有进入过弃牌堆的花色数量）。',
  ['$qinshen1'] = '怀藏拙之心，赚不名之利。',
  ['$qinshen2'] = '勤可补拙，慎可避祸。',
}

qinshen:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qinshen.name) and player.phase == Player.Discard
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local suits = {1,2,3,4}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            local suit = Fk:getCardById(info.cardId).suit
            table.removeOne(suits, suit)
          end
        end
      end
      return #suits == 0
    end, Player.HistoryTurn)
    local n = #suits
    if n > 0 then
      event:setCostData(self, n)
      return room:askToSkillInvoke(player, {
        skill_name = qinshen.name,
        prompt = "#qinshen-invoke:::"..n
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self), qinshen.name)
  end,
})

return qinshen
