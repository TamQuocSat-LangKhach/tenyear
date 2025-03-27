local xingmen = fk.CreateSkill {
  name = "xingmen",
}

Fk:loadTranslationTable{
  ["xingmen"] = "兴门",
  [":xingmen"] = "当你因〖守执〗弃置手牌后，你可以回复1点体力。当你一次从牌堆获得超过一张牌后，你使用其中的红色牌不能被响应。",

  ["#xingmen_recover"] = "兴门：你可以回复1点体力",
  ["@@xingmen-inhand"] = "兴门",

  ["$xingmen1"] = "尔等，休道我关氏无人！",
  ["$xingmen2"] = "义在人心，人人皆可成关公！",
}

xingmen:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xingmen.name) and player:isWounded() then
      for _, move in ipairs(data) do
        if move.from == player and move.skillName == "shouzhi" and move.moveReason == fk.ReasonDiscard then
          return true
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = xingmen.name,
      prompt = "#xingmen_recover",
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = xingmen.name,
    }
  end,

  can_refresh = function (self, event, target, player, data)
    if player:hasSkill(xingmen.name) then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.DrawPile then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DrawPile then
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end
    if #cards > 1 then
      cards = table.filter(cards, function (id)
        return table.contains(player:getCardIds("h"), id) and Fk:getCardById(id).color == Card.Red
      end)
      if #cards > 0 then
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id), "@@xingmen-inhand", 1)
        end
      end
    end
  end,
})

xingmen:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.every(Card:getIdList(data.card), function (id)
        return Fk:getCardById(id):getMark("@@xingmen-inhand") > 0
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

return xingmen
