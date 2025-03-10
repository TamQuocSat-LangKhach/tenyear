local sanshi = fk.CreateSkill {
  name = "sanshi"
}

Fk:loadTranslationTable{
  ['sanshi'] = '散士',
  ['@@expendables-inhand'] = '死士',
  [':sanshi'] = '锁定技，游戏开始时，你将牌堆里每个点数的随机一张牌标记为“死士”牌。一名角色的回合结束时，你获得弃牌堆里于本回合非因你使用或打出而移至此区域的“死士”牌。当你使用“死士”牌时，你令此牌不可被响应。',
  ['$sanshi1'] = '春雨润物，未觉其暖，已见其青。',
  ['$sanshi2'] = '养士效孟尝，用时可得千臂之助力。',
}

sanshi:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(sanshi) then return false end
    local data = event.data[1]
    return player == target and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not data.card:isVirtual() and table.contains(player:getTableMark(sanshi.name), data.card.id)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local data = event.data[1]
    data.disresponsiveList = table.map(room.players, Util.IdMapper)
  end,
})

sanshi:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(sanshi) then return false end
    local room = player.room
    local cards = table.filter(player:getTableMark(sanshi.name), function (id)
      return room:getCardArea(id) == Card.DiscardPile
    end)

    if #cards == 0 then return false end

    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if not turn_event then return false end

    local ids = {}
    room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.removeOne(cards, id) then
            if move.toArea == Card.DiscardPile then
              if move.moveReason == fk.ReasonUse then
                local use_event = e:findParent(GameEvent.UseCard)
                if not use_event or use_event.data[1].from ~= player.id then
                  table.insert(ids, id)
                end
              elseif move.moveReason == fk.ReasonResponse then
                local use_event = e:findParent(GameEvent.RespondCard)
                if not use_event or use_event.data[1].from ~= player.id then
                  table.insert(ids, id)
                end
              else
                table.insert(ids, id)
              end
            end
          end
        end
      end
    end, turn_event.id)

    if #ids > 0 then
      event:setCostData(skill, ids)
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:moveCardTo(table.simpleClone(event:getCostData(skill)), Card.PlayerHand, player, fk.ReasonPrey, sanshi.name)
  end,
})

sanshi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player) return true end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cardmap = {}
    for i = 1, 13 do
      table.insert(cardmap, {})
    end

    for _, id in ipairs(room.draw_pile) do
      local n = Fk:getCardById(id).number
      if n > 0 and n < 14 then
        table.insert(cardmap[n], id)
      end
    end

    local cards = {}
    for _, ids in ipairs(cardmap) do
      if #ids > 0 then
        table.insert(cards, table.random(ids))
      end
    end

    room:setPlayerMark(player, sanshi.name, cards)
  end,
})

sanshi:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player) return not player.dead and #player:getTableMark(sanshi.name) > 0 end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = player:getTableMark(sanshi.name)
    local handcards = player:getCardIds(Player.Hand)

    for _, cid in ipairs(cards) do
      local card = Fk:getCardById(cid)
      if table.contains(handcards, cid) and card:getMark("@@expendables-inhand") == 0 then
        room:setCardMark(card, "@@expendables-inhand", 1)
      end
    end
  end,
})

return sanshi
