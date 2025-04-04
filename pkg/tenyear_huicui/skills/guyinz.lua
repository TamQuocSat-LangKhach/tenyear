local guyinz = fk.CreateSkill {
  name = "guyinz",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["guyinz"] = "顾音",
  [":guyinz"] = "锁定技，你没有初始手牌，其他角色的初始手牌+1。其他角色的初始手牌被使用或弃置进入弃牌堆后，你摸一张牌。",

  ["$guyinz1"] = "曲有误，不可不顾。",
  ["$guyinz2"] = "兀音曳绕梁，愿君去芜存菁。",
}

guyinz:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(guyinz.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonDiscard) then
          for _, info in ipairs(move.moveInfo) do
            if info.extra_data and info.extra_data.guyinz and info.extra_data.guyinz ~= player.id then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, guyinz.name)
  end,

  can_refresh = function (self, event, target, player, data)
    if player.seat == 1 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          return true
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark(guyinz.name) ~= 0 then
            if move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonDiscard then
              info.extra_data = info.extra_data or {}
              info.extra_data.guyinz = Fk:getCardById(info.cardId):getMark(guyinz.name)
            end
            player.room:setCardMark(Fk:getCardById(info.cardId), guyinz.name, 0)
          end
        end
      end
    end
  end,
})

guyinz:addEffect(fk.DrawInitialCards, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(guyinz.name)
  end,
  on_refresh = function (self, event, target, player, data)
    if target == player then
      data.num = -999
    else
      data.num = data.num + 1
    end
  end,
})

guyinz:addEffect(fk.AfterDrawInitialCards, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(guyinz.name) and target ~= player and not target:isKongcheng()
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(target:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), guyinz.name, target.id)
    end
  end,
})

return guyinz
