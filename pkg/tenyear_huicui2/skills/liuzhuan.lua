local liuzhuan = fk.CreateSkill {
  name = "liuzhuan"
}

Fk:loadTranslationTable{
  ['liuzhuan'] = '流转',
  ['@@liuzhuan-inhand-turn'] = '流转',
  [':liuzhuan'] = '锁定技，其他角色的回合内，其于摸牌阶段外获得的牌无法对你使用，这些牌本回合进入弃牌堆后，你获得之。',
  ['$liuzhuan1'] = '身似浮萍，随波逐流。',
  ['$liuzhuan2'] = '辗转四方，宦游八州。',
}

liuzhuan:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(liuzhuan) then return false end
    local room = player.room
    local current = room.current
    if current == player or current.phase == Player.NotActive then return false end
    local toMarked, toObtain = {}, {}
    local id
    for _, move in ipairs(data) do
      if current.phase ~= Player.Draw and move.to == current.id and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == current then
            table.insert(toMarked, id)
          end
        end
      end
      local mark = player:getTableMark("liuzhuan_record-turn")
      if move.toArea == Card.DiscardPile and #mark > 0 then
        for _, info in ipairs(move.moveInfo) do
          id = info.cardId
          --for stupid manjuan
          if info.fromArea ~= Card.DiscardPile and table.removeOne(mark, id) and room:getCardArea(id) == Card.DiscardPile then
            table.insert(toObtain, id)
          end
        end
      end
    end
    toObtain = U.moveCardsHoldingAreaCheck(room, toObtain)
    if #toMarked > 0 or #toObtain > 0 then
      event:setCostData(skill, {toMarked, toObtain})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local toMarked = table.simpleClone(event:getCostData(skill)[1])
    local toObtain = table.simpleClone(event:getCostData(skill)[2])
    local mark = player:getTableMark("liuzhuan_record-turn")
    table.insertTableIfNeed(mark, toMarked)
    room:setPlayerMark(player, "liuzhuan_record-turn", mark)
    for _, id in ipairs(toMarked) do
      room:setCardMark(Fk:getCardById(id), "@@liuzhuan-inhand-turn", 1)
    end
    if #toObtain > 0 then
      room:moveCardTo(toObtain, Player.Hand, player, fk.ReasonJustMove, liuzhuan.name, "", true, player.id)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    if event == fk.Death and player ~= target then return false end
    return #player:getTableMark("liuzhuan_record-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("liuzhuan_record-turn")
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to ~= room.current.id and (move.toArea == Card.PlayerHand or move.toArea == Card.PlayerEquip) then
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(mark, info.cardId)
          end
        end
      end
      room:setPlayerMark(player, "liuzhuan_record-turn", mark)
    elseif event == fk.Death then
      local card
      for _, id in ipairs(mark) do
        card = Fk:getCardById(id)
        if card:getMark("@@liuzhuan-inhand-turn") > 0 and table.every(room.alive_players, function (p)
          return not table.contains(p:getTableMark("liuzhuan_record-turn"), id)
        end) then
          room:setCardMark(card, "@@liuzhuan-inhand-turn", 0)
        end
      end
    end
  end,
})

liuzhuan:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    if not to:hasSkill(liuzhuan) then return false end
    local mark = to:getTableMark("liuzhuan_record-turn")
    if #mark == 0 then return false end
    for _, id in ipairs(Card:getIdList(card)) do
      if table.contains(mark, id) and table.contains(from:getCardIds("he"), id) then
        return true
      end
    end
  end,
})

return liuzhuan
