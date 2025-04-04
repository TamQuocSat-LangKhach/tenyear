local lingkong = fk.CreateSkill {
  name = "lingkong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lingkong"] = "灵箜",
  [":lingkong"] = "锁定技，游戏开始时，你的初始手牌增加“箜篌”标记且不计入手牌上限。每回合你于摸牌阶段外首次获得牌后，将这些牌标记为“箜篌”。",

  ["@@konghou-inhand"] = "箜篌",

  ["$lingkong1"] = "箜篌奏晚歌，渔樵有归期。",
  ["$lingkong2"] = "吴宫绿荷惊涟漪，飞燕啄新泥。",
}

lingkong:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lingkong.name) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), "@@konghou-inhand", 1)
    end
  end,
})

lingkong:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(lingkong.name) and player.room.current.phase ~= Player.Draw and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      local cards = {}
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if table.contains(player:getCardIds("h"), id) then
              table.insertIfNeed(cards, id)
            end
          end
        end
      end
      cards = player.room.logic:moveCardsHoldingAreaCheck(cards)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(event:getCostData(self).cards) do
      room:setCardMark(Fk:getCardById(id), "@@konghou-inhand", 1)
    end
  end,
})

lingkong:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@konghou-inhand") > 0
  end,
})

lingkong:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id), "@@konghou-inhand", 0)
  end
end)

return lingkong
