local yunzheng = fk.CreateSkill {
  name = "yunzheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yunzheng"] = "韵筝",
  [":yunzheng"] = "锁定技，游戏开始时，你的初始手牌增加“筝”标记且不计入手牌上限。手牌有“筝”的其他角色非锁定技失效。",

  ["@@yunzheng-inhand"] = "筝",
  ["@yunzheng"] = "筝",

  ["$yunzheng1"] = "佳人弄青丝，柔荑奏鸣筝。",
  ["$yunzheng2"] = "玉柱冷寒雪，清商怨羽声。",
}

yunzheng:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yunzheng.name) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Hand)
    local card
    for _, id in ipairs(cards) do
      card = Fk:getCardById(id)
      room:setCardMark(card, "@@yunzheng-inhand", 1)
      room:setCardMark(card, yunzheng.name, 1)
    end
    room:setPlayerMark(player, "@yunzheng", #cards)
  end,
})

yunzheng:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
      if move.to == player and move.toArea == Player.Hand and #move.moveInfo > 0 then
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local card
    local x = #table.filter(player:getCardIds("h"), function (id)
      card = Fk:getCardById(id)
      if card:getMark(yunzheng.name) > 0 then
        if card:getMark("@@yunzheng-inhand") == 0 then
          room:setCardMark(card, "@@yunzheng-inhand", 1)
        end
        return true
      end
    end)
    if player:getMark("@yunzheng") ~= x then
      room:setPlayerMark(player, "@yunzheng", x)
    end
  end,
})

yunzheng:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if table.every(room.alive_players, function (p)
    return not p:hasSkill(yunzheng.name, true)
  end) then
    for _, p in ipairs(room.alive_players) do
      for _, id in ipairs(p:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "@@yunzheng-inhand", 0)
      end
      room:setPlayerMark(p, "@yunzheng", 0)
    end
  end
end)

yunzheng:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(yunzheng.name) and card:getMark("yunzheng") > 0
  end,
})

yunzheng:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    if from:getMark("@yunzheng") > 0 and skill:isPlayerSkill(from) and
      table.contains(from:getSkillNameList(), skill:getSkeleton().name) and not skill:hasTag(Skill.Compulsory) then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= from and p:hasSkill(yunzheng.name)
      end)
    end
  end,
})

return yunzheng
