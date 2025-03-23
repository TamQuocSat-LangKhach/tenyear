local falu = fk.CreateSkill {
  name = "falu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["falu"] = "法箓",
  [":falu"] = "锁定技，当你的牌因弃置而移至弃牌堆后，根据这些牌的花色，你获得对应标记：<br>"..
  "♠，你获得1枚“紫微”；<br>♣，你获得1枚“后土”；<br>"..
  "<font color='red'>♥</font>，你获得1枚“玉清”；<br><font color='red'>♦</font>，你获得1枚“勾陈”。<br>"..
  "每种标记限拥有一个。游戏开始时，你获得以上四种标记。",

  ["$falu1"] = "求法之道，以司箓籍。",
  ["$falu2"] = "取舍有法，方得其法。",
}

falu:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(falu.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    for i = 1, 4 do
      room:addPlayerMark(player, "@@falu" .. suits[i], 1)
    end
  end,
})

falu:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(falu.name) then
      local suits = {}
      for _, move in ipairs(data) do
        if move.from == player and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              local suit = Fk:getCardById(info.cardId):getSuitString()
              if player:getMark("@@falu" .. suit) == 0 then
                table.insertIfNeed(suits, suit)
              end
            end
          end
        end
      end
      if #suits > 0 then
        event:setCostData(self, {choice = suits})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, suit in ipairs(event:getCostData(self).choice) do
      room:addPlayerMark(player, "@@falu" .. suit, 1)
    end
  end,
})

falu:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
    room:setPlayerMark(player, "@@falu"..suit, 0)
  end
end)

return falu
