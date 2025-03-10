local ty__xiahui = fk.CreateSkill {
  name = "ty__xiahui"
}

Fk:loadTranslationTable{
  ['ty__xiahui'] = '黠慧',
  ['@@ty__xiahui-inhand'] = '黠慧',
  [':ty__xiahui'] = '锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌时，这些牌标记为“黠慧”，其不能使用、打出、弃置“黠慧”牌直到其体力值减少。其他角色回合结束时，若其本回合失去过“黠慧”牌且手牌中没有“黠慧”牌，其失去1点体力。',
}

ty__xiahui:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return player:hasSkill(ty__xiahui.name) and card.color == Card.Black
  end,
})

ty__xiahui:addEffect({fk.AfterCardsMove, fk.HpChanged, fk.TurnEnd}, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove and player:hasSkill(ty__xiahui.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black then
              return true
            end
          end
        end
      end
    elseif event == fk.HpChanged then
      return target == player and data.num < 0 and
        table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@ty__xiahui-inhand") > 0 end)
    elseif event == fk.TurnEnd then
      return target == player and target:getMark("ty__xiahui-turn") > 0 and
        not table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@ty__xiahui-inhand") > 0 end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          local to = room:getPlayerById(move.to)
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black and table.contains(to:getCardIds("h"), info.cardId) then
              room:setCardMark(Fk:getCardById(info.cardId), "@@ty__xiahui-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.HpChanged then
      for _, id in ipairs(player:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "@@ty__xiahui-inhand", 0)
      end
    elseif event == fk.TurnEnd then
      room:loseHp(player, 1, "ty__xiahui")
    end
  end,

  can_refresh = function(self, player, data)
    if player.phase ~= Player.NotActive and player:getMark("ty__xiahui-turn") == 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@ty__xiahui-inhand") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, player)
    player.room:setPlayerMark(player, "ty__xiahui-turn", 1)
  end,
})

ty__xiahui:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.find(cards, function(id) return Fk:getCardById(id):getMark("@@ty__xiahui-inhand") > 0 end)
  end,
  prohibit_response = function(self, player, card)
    local cards = card:isVirtual() and card.subcards or {card.id}
    return table.find(cards, function(id) return Fk:getCardById(id):getMark("@@ty__xiahui-inhand") > 0 end)
  end,
  prohibit_discard = function(self, player, card)
    return card:getMark("@@ty__xiahui-inhand") > 0
  end,
})

return ty__xiahui
