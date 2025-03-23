local xingmen = fk.CreateSkill {
  name = "xingmen"
}

Fk:loadTranslationTable{
  ['xingmen'] = '兴门',
  ['@@xingmen-inhand'] = '兴门',
  [':xingmen'] = '当你因执行〖守执〗的效果而弃置手牌后，你可以回复1点体力。当你因摸牌而得到牌后，若这些牌数大于1，你使用其中的红色牌不能被响应。',
  ['$xingmen1'] = '尔等，休道我关氏无人！',
  ['$xingmen2'] = '义在人心，人人皆可成关公！',
}

xingmen:addEffect(fk.AfterCardsMove, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xingmen.name) then
      local cards = {}
      local recover = false
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand and move.moveReason == fk.ReasonDraw then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(cards, info.cardId)
          end
        end
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and
          move.skillName == shouzhi.name and #move.moveInfo > 0 and player:isWounded() then
          recover = true
        end
      end
      if #cards < 2 then
        cards = {}
      end
      cards = table.filter(cards, function (id)
        return Fk:getCardById(id).color == Card.Red
      end)
      if #cards > 0 or recover then
        event:setCostData(self, {cards, recover})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Hand)
    for _, id in ipairs(event:getCostData(self)[1]) do
      if table.contains(cards, id) then
        room:setCardMark(Fk:getCardById(id), "@@xingmen-inhand", 1)
      end
    end
    if event:getCostData(self)[2] and room:askToSkillInvoke(player, { skill_name = xingmen.name }) then
      room:notifySkillInvoked(player, xingmen.name)
      player:broadcastSkillInvoke(xingmen.name)
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = xingmen.name
      }
    end
  end,
})

xingmen:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return player == target and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not data.card:isVirtual() and data.card:getMark("@@xingmen-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.players, Util.IdMapper)
  end,
})

return xingmen
