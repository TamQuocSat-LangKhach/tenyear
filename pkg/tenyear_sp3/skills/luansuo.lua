local luansuo = fk.CreateSkill {
  name = "luansuo"
}

Fk:loadTranslationTable{
  ['luansuo'] = '鸾锁',
  ['#luansuo_filter'] = '鸾锁',
  [':luansuo'] = '锁定技，你的回合内，所有角色不能弃置手牌，与本回合进入弃牌堆的牌花色均不同的手牌视为【铁索连环】。',
  ['$luansuo1'] = '六道锁凡尘，死生皆如逆旅。',
  ['$luansuo2'] = '命数如织网，无人不坠因果。',
}

luansuo:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player)
    return player == target and player:hasSkill(luansuo.name)
  end,
  on_cost = function (skill, event, target, player)
    event:setCostData(skill, { tos = table.map(player.room.alive_players, Util.IdMapper) })
  end,
  on_use = function (skill, event, target, player)
    local room = player.room
    room:setBanner("luansuo-turn", {})
    for _, p in ipairs(room.alive_players) do
      for _, id in ipairs(p:getCardIds(Player.Hand)) do
        room:setCardMark(Fk:getCardById(id), "luansuo-inhand-turn", 1)
      end
      p:filterHandcards()
    end
  end,
})

luansuo:addEffect(fk.BeforeCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player.room:getCurrent() ~= player or not player:hasSkill(luansuo.name) then return false end
    for _, move in ipairs(data) do
      if move.from and move.moveReason == fk.ReasonDiscard and not player.room:getPlayerById(move.from).dead then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_cost = function (skill, event, target, player)
    event:setCostData(skill, nil)
    return true
  end,
  on_use = function (skill, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.from and move.moveReason == fk.ReasonDiscard and not player.room:getPlayerById(move.from).dead then
        local moveInfos = {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            table.insert(ids, info.cardId)
          else
            table.insert(moveInfos, info)
          end
        end
        if #ids > 0 then
          move.moveInfo = moveInfos
        end
      end
    end
    if #ids > 0 then
      player.room:sendLog{
        type = "#cancelDismantle",
        card = ids,
        arg = luansuo.name,
      }
    end
  end,
})

luansuo:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player)
    return player == player.room.current and player.room:getBanner("luansuo-turn") ~= nil
  end,
  on_refresh = function (skill, event, target, player)
    local room = player.room
    local mark = room:getBanner("luansuo-turn")
    if type(mark) ~= "table" then
      mark = {}
    elseif #mark == 4 then
      return
    end
    local suit
    local mark_change = false
    for _, move in ipairs(event:getCostData(skill)) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          suit = Fk:getCardById(info.cardId, true).suit
          if suit ~= Card.NoSuit and table.insertIfNeed(mark, suit) then
            mark_change = true
          end
        end
      end
    end
    if mark_change then
      room:setBanner("luansuo-turn", mark)
      for _, p in ipairs(room.alive_players) do
        p:filterHandcards()
      end
    end
  end,
})

luansuo:addEffect(fk.AfterTurnEnd, {
  can_refresh = function(self, event, target, player)
    return player == player.room.current and player.room:getBanner("luansuo-turn") ~= nil
  end,
  on_refresh = function (skill, event, target, player)
    local room = player.room
    room:setBanner("luansuo-turn", 0)
  end,
})

local luansuo_filter = fk.CreateFilterSkill{
  name = "#luansuo_filter",
  mute = true,
  card_filter = function(self, player, card, isJudgeEvent)
    return table.contains(player:getCardIds("h"), card.id) and card.suit ~= Card.NoSuit and
      card:getMark("luansuo-inhand-turn") > 0 and not table.contains(Fk:currentRoom():getBanner("luansuo-turn"), card.suit)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("iron_chain", card.suit, card.number)
  end,
}

local luansuo_prohibit = fk.CreateProhibitSkill{
  name = "#luansuo_prohibit",
  prohibit_discard = function(self, player, card)
    if table.contains(player:getCardIds("h"), card.id) then
      local currentPlayer = Fk:currentRoom():getCurrent()
      return currentPlayer and currentPlayer:hasSkill(luansuo.name)
    end
  end,
}

return luansuo
