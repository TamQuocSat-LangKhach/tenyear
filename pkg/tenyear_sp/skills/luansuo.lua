local luansuo = fk.CreateSkill {
  name = "luansuo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["luansuo"] = "鸾锁",
  [":luansuo"] = "锁定技，你的回合内，所有角色不能弃置手牌，与本回合进入弃牌堆的牌花色均不同的手牌视为【铁索连环】。",

  ["$luansuo1"] = "六道锁凡尘，死生皆如逆旅。",
  ["$luansuo2"] = "命数如织网，无人不坠因果。",
}

luansuo:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(luansuo.name)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = player.room.alive_players })
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setBanner("luansuo-turn", {})
    for _, p in ipairs(room.alive_players) do
      for _, id in ipairs(p:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "luansuo-inhand-turn", 1)
      end
      p:filterHandcards()
    end
  end,
})

luansuo:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player.room.current == player and player:hasSkill(luansuo.name) then
      for _, move in ipairs(data) do
        if move.from and move.moveReason == fk.ReasonDiscard and not move.from.dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.from and move.moveReason == fk.ReasonDiscard and not move.from.dead then
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
  end,
})

luansuo:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player.seat == 1 and player.room:getBanner("luansuo-turn") and
      #player.room:getBanner("luansuo-turn") < 4
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = room:getBanner("luansuo-turn")
    local suit
    local mark_change = false
    for _, move in ipairs(data) do
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

luansuo:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return table.contains(player:getCardIds("h"), card.id) and card.suit ~= Card.NoSuit and
      card:getMark("luansuo-inhand-turn") > 0 and
      not table.contains(Fk:currentRoom():getBanner("luansuo-turn"), card.suit)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("iron_chain", card.suit, card.number)
  end,
})

luansuo:addEffect("prohibit", {
  prohibit_discard = function(self, player, card)
    return table.contains(player:getCardIds("h"), card.id) and Fk:currentRoom():getCurrent():hasSkill(luansuo.name)
  end,
})

return luansuo
