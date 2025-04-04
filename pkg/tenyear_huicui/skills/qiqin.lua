local qiqin = fk.CreateSkill {
  name = "qiqin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qiqin"] = "绮琴",
  [":qiqin"] = "锁定技，游戏开始时，你的初始手牌增加“琴”标记且不计入手牌上限。准备阶段，你获得弃牌堆中所有“琴”牌。",

  ["@@qiqin-inhand"] = "琴",
}

qiqin:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qiqin.name) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("h")
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@qiqin-inhand", 1)
      room:setCardMark(Fk:getCardById(id), qiqin.name, 1)
    end
  end,
})

qiqin:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiqin.name) and player.phase == Player.Start and
      table.find(player.room.discard_pile, function(id)
        return Fk:getCardById(id):getMark(qiqin.name) > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(room.discard_pile, function(id)
      return Fk:getCardById(id):getMark(qiqin.name) > 0
    end)
    room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, qiqin.name, nil, false, player)
  end,
})

qiqin:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      room:setCardMark(card, "@@qiqin-inhand", (card:getMark(qiqin.name) > 0 and player:hasSkill(qiqin.name, true)) and 1 or 0)
    end
  end,
})

qiqin:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(qiqin.name) and card:getMark(qiqin.name) > 0
  end,
})

qiqin:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id), "@@qiqin-inhand", 0)
  end
end)

return qiqin
