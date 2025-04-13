local jiaowei = fk.CreateSkill {
  name = "jiaowei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiaowei"] = "焦尾",
  [":jiaowei"] = "锁定技，游戏开始时，你的初始手牌增加“弦”标记且不计入手牌上限。当你失去“弦”后，防止你本回合下一次受到的伤害。",

  ["@@jiaowei-inhand"] = "弦",
  ["@@jiaowei-turn"] = "焦尾",

  ["$jiaowei1"] = "",
  ["$jiaowei2"] = "",
}

jiaowei:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiaowei.name) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), "@@jiaowei-inhand", 1)
    end
    room:setPlayerMark(player, jiaowei.name, table.simpleClone(player:getCardIds("h")))
  end,
})

jiaowei:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(jiaowei.name, true) then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) then
              return true
            end
          end
        end
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and table.contains(player:getTableMark(jiaowei.name), info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@jiaowei-inhand") > 0
    end)
    local yes = false
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and
            table.contains(player:getTableMark(jiaowei.name), info.cardId) and
            not table.contains(cards, info.cardId) then
            yes = true
          end
        end
      end
    end
    room:setPlayerMark(player, jiaowei.name, cards)
    if yes and player:hasSkill(jiaowei.name) and room.current.phase ~= Player.NotActive then
      room:setPlayerMark(player, "@@jiaowei-turn", 1)
    end
  end,
})

jiaowei:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@jiaowei-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
    player.room:setPlayerMark(player, "@@jiaowei-turn", 0)
  end,
})

jiaowei:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@jiaowei-inhand") > 0
  end,
})

jiaowei:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, jiaowei.name, 0)
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id), "@@jiaowei-inhand", 0)
  end
end)

return jiaowei
