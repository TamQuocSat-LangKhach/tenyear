local lieti = fk.CreateSkill {
  name = "lieti",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lieti"] = "烈悌",
  [":lieti"] = "锁定技，分发起始手牌时，你额外获得一组初始手牌并增加武将名称标记（第一组标记为“袁术”，第二组标记为“袁绍”）；"..
  "当你获得手牌时，根据当前武将为手牌增加武将标记。你只能使用或打出当前武将标记的手牌。非当前武将标记的手牌不计手牌上限。",

  ["@lieti-inhand"] = "",
}

lieti:addEffect(fk.DrawInitialCards, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(lieti.name) and data.num > 0
  end,
  on_use = function (self, event, target, player, data)
    data.num = data.num * 2
  end,
})

lieti:addEffect(fk.AfterDrawInitialCards, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(lieti.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local n = data.num / 2
    local cards = table.simpleClone(player:getCardIds("h"))
    for i = 1, n do
      room:setCardMark(Fk:getCardById(cards[i]), "@lieti-inhand", Fk:translate("yuanshu"))
    end
    if #cards > n then
      for i = n, math.min(#cards, n * 2) do
        room:setCardMark(Fk:getCardById(cards[i]), "@lieti-inhand", Fk:translate("yuanshao"))
      end
    end
  end,
})

lieti:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(lieti.name) then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand then
          return true
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end
    local mark = player:getMark("@shigong")
    for _, id in ipairs(ids) do
      player.room:setCardMark(Fk:getCardById(id), "@lieti-inhand", mark)
    end
  end,
})

lieti:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:hasSkill(lieti.name) and not (player:hasSkill("shigong", true) and player:getMark("shigong-turn") == 0) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and
        table.find(subcards, function(id)
          return table.contains(player:getCardIds("h"), id) and
            Fk:getCardById(id):getMark("@lieti-inhand") ~= player:getMark("@shigong")
        end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:hasSkill(lieti.name) and not (player:hasSkill("shigong", true) and player:getMark("shigong-turn") == 0) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and
        table.find(subcards, function(id)
          return table.contains(player:getCardIds("h"), id) and
            Fk:getCardById(id):getMark("@lieti-inhand") ~= player:getMark("@shigong")
        end)
    end
  end,
})

lieti:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    return player:hasSkill(lieti.name) and card:getMark("@lieti-inhand") ~= player:getMark("@shigong")
  end,
})

lieti:addLoseEffect(function (self, player, is_death)
  for _, id in ipairs(player:getCardIds("h")) do
    player.room:setCardMark(Fk:getCardById(id), "@lieti-inhand", 0)
  end
end)

return lieti
