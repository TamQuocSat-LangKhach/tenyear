local yitong = fk.CreateSkill {
  name = "yitong"
}

Fk:loadTranslationTable{
  ['yitong'] = '异瞳',
  ['@yitong'] = '异瞳',
  ['#yitong-suit'] = '异瞳：请选择一种花色',
  [':yitong'] = '锁定技，游戏开始时，你选择一种花色。每回合限一次，当此花色的牌因使用而移至弃牌堆后，你随机获得除此花色外的不同花色的牌各一张。',
  ['$yitong1'] = '清风与明月，皆入我眸中。',
  ['$yitong2'] = '原来荷包里藏了好东西啊。',
}

yitong:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yitong.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
    if event == fk.GameStart then
      local suit = room:askToChoice(player, {
        choices = all_suits,
        skill_name = yitong.name,
        prompt = "#yitong-suit"
      })
      room:setPlayerMark(player, "@yitong", suit)
    end
  end,
})

yitong:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yitong.name) and player:getMark("@yitong") ~= 0 and player:getMark("yitong_draw-turn") == 0 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getSuitString(true) == player:getMark("@yitong") then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
    if player:getMark("@yitong") ~= 0 and player:getMark("yitong_draw-turn") == 0 then
      room:setPlayerMark(player, "yitong_draw-turn", 1)
      table.removeOne(all_suits, player:getMark("@yitong"))
      local cards = {}
      for _, suit in ipairs(all_suits) do
        local pattern = ".|.|"..string.sub(suit, 5)
        local card = room:getCardsFromPileByRule(pattern, 1, "drawPile")
        if #card > 0 then
          table.insert(cards, card[1])
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, yitong.name, nil, false, player.id)
      end
    end
  end,
})

return yitong
