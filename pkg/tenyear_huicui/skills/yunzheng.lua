local yunzheng = fk.CreateSkill {
  name = "yunzheng"
}

Fk:loadTranslationTable{
  ['yunzheng'] = '韵筝',
  ['@@yunzheng-inhand'] = '筝',
  ['@yunzheng'] = '筝',
  [':yunzheng'] = '锁定技，游戏开始时，你的初始手牌增加“筝”标记且不计入手牌上限。手牌区里有“筝”的其他角色的不带“锁定技”标签的技能无效。',
  ['$yunzheng1'] = '佳人弄青丝，柔荑奏鸣筝。',
  ['$yunzheng2'] = '玉柱冷寒雪，清商怨羽声。',
}

yunzheng:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yunzheng) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Hand)
    local card
    for _, id in ipairs(cards) do
      card = Fk:getCardById(id)
      room:setCardMark(card, "@@yunzheng-inhand", 1)
      room:setCardMark(card, "yunzheng", 1)
    end
    room:setPlayerMark(player, "@yunzheng", #cards)
  end,
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
      if move.to == player.id and move.toArea == Player.Hand and #move.moveInfo > 0 then
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local card
    local x = #table.filter(player:getCardIds(Player.Hand), function (id)
      card = Fk:getCardById(id)
      if card:getMark("yunzheng") > 0 then
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
  on_lose = function(self, player)
    local room = player.room
    if table.every(room.alive_players, function (p)
      return not p:hasSkill(yunzheng, true)
    end) then
      for _, p in ipairs(room.alive_players) do
        for _, id in ipairs(p:getCardIds(Player.Hand)) do
          room:setCardMark(Fk:getCardById(id), "@@yunzheng-inhand", 0)
        end
        room:setPlayerMark(p, "@yunzheng", 0)
      end
    end
  end,
})

local yunzheng_maxcards = fk.CreateMaxCardsSkill{
  name = "#yunzheng_maxcards",
  exclude_from = function(self, player, card)
    return player:hasSkill(yunzheng) and card:getMark("yunzheng") > 0
  end,
}

local yunzheng_invalidity = fk.CreateInvaliditySkill {
  name = "#yunzheng_invalidity",
  invalidity_func = function(self, from, skill_check)
    if from:getMark("@yunzheng") > 0 and table.contains(from.player_skills, skill_check)
      and skill_check.frequency ~= Skill.Compulsory and skill_check.frequency ~= Skill.Wake and skill_check:isPlayerSkill(from) then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= from and p:hasSkill(yunzheng)
      end)
    end
  end,
}

return yunzheng
