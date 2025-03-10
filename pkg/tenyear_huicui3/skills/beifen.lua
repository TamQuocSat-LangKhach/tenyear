local beifen = fk.CreateSkill {
  name = "beifen"
}

Fk:loadTranslationTable{
  ['beifen'] = '悲愤',
  ['@shuangjia'] = '胡笳',
  ['@@shuangjia-inhand'] = '胡笳',
  ['shuangjia'] = '霜笳',
  [':beifen'] = '锁定技，当你失去“胡笳”后，你获得与手中“胡笳”花色均不同的牌各一张。你手中“胡笳”少于其他牌时，你使用牌无距离和次数限制。',
  ['$beifen1'] = '此心如置冰壶，无物可暖。',
  ['$beifen2'] = '年少爱登楼，欲说语还休。',
}

-- 触发技部分
beifen:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(beifen) then
      local mark = player:getTableMark("beifen")
      if #mark == 0 then return false end
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and table.contains(mark, info.cardId) then
              table.insert(cards, info.cardId)
            end
          end
        end
      end
      if #cards > 0 then
        event:setCostData(self, cards)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("beifen")
    for _, id in ipairs(event:getCostData(self)) do
      table.removeOne(mark, id)
    end
    room:setPlayerMark(player, "beifen", #mark > 0 and mark or 0)
    room:setPlayerMark(player, "@shuangjia", #mark)

    local suits = {"heart", "diamond", "spade", "club"}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      if card:getMark("@@shuangjia-inhand") > 0 then
        table.removeOne(suits, card:getSuitString())
      end
    end
    if #suits == 0 then return false end
    local patternTable = {}
    for _, suit in ipairs(suits) do
      patternTable[suit] = {}
    end
    for _, id in ipairs(room.draw_pile) do
      local suit = Fk:getCardById(id):getSuitString()
      if table.contains(suits, suit) then
        table.insert(patternTable[suit], id)
      end
    end
    local cards = {}
    for _, suit in ipairs(suits) do
      local ids = patternTable[suit]
      if #ids > 0 then
        table.insert(cards, table.random(ids))
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = beifen.name,
      })
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(beifen) and player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
      player:getHandcardNum() > 2 * player:getMark("@shuangjia")
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

-- 目标修正技能部分
beifen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(beifen) and player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
      player:getHandcardNum() > 2 * player:getMark("@shuangjia")
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(beifen) and player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
      player:getHandcardNum() > 2 * player:getMark("@shuangjia")
  end,
})

return beifen
