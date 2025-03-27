local qiqin = fk.CreateSkill {
  name = "qiqin"
}

Fk:loadTranslationTable{
  ['qiqin'] = '绮琴',
  ['@@qiqin-inhand'] = '琴',
  [':qiqin'] = '锁定技，游戏开始时，你的初始手牌增加“琴”标记且不计入手牌上限。准备阶段，你获得弃牌堆中所有“琴”牌。',
}

qiqin:addEffect(fk.GameStart, {
  anim_type = "special",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Hand)
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@qiqin-inhand", 1)
      room:setCardMark(Fk:getCardById(id), "qiqin", 1)
    end
  end,
})

qiqin:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) and target == player and player.phase == Player.Start then
      local get = table.filter(player.room.discard_pile, function(id)
        return Fk:getCardById(id):getMark("qiqin") > 0
      end)
      if #get > 0 then
        event:setCostData(skill.name, get)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(skill.name), Player.Hand, player, fk.ReasonJustMove, qiqin.name, "", false, player.id)
  end,
})

qiqin:addEffect(fk.AfterCardsMove, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      local value = (card:getMark("qiqin") > 0 and player:hasSkill(skill.name, true)) and 1 or 0
      if card:getMark("@@qiqin-inhand") ~= value then
        room:setCardMark(card, "@@qiqin-inhand", value)
      end
    end
  end,
})

qiqin:addEffect('maxcards', {
  name = "#qiqin_maxcards",
  exclude_from = function(self, player, card)
    return player:hasSkill(qiqin) and card:getMark("qiqin") > 0
  end,
})

qiqin:addEffect(nil, {
  on_lose = function(self, player)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      room:setCardMark(Fk:getCardById(id), "@@qiqin-inhand", 0)
    end
  end,
})

return qiqin
