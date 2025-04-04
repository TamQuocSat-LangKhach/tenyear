local beifen = fk.CreateSkill {
  name = "beifen",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["beifen"] = "悲愤",
  [":beifen"] = "锁定技，当你失去“胡笳”后，你获得与手中“胡笳”花色均不同的牌各一张。你手中“胡笳”少于其他牌时，你使用牌无距离和次数限制。",

  ["$beifen1"] = "此心如置冰壶，无物可暖。",
  ["$beifen2"] = "年少爱登楼，欲说语还休。",
}

beifen:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(beifen.name) and player:getMark("shuangjia") ~= 0 then
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and table.contains(player:getTableMark("shuangjia"), info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(event:getCostData(self).cards) do
      room:removeTableMark(player, "shuangjia", id)
    end
    room:setPlayerMark(player, "@shuangjia", #player:getTableMark("shuangjia"))

    local suits = {"heart", "diamond", "spade", "club"}
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card:getMark("@@shuangjia-inhand") > 0 then
        table.removeOne(suits, card:getSuitString())
      end
    end
    if #suits == 0 then return end
    local cards = {}
    for _, suit in ipairs(suits) do
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..suit))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = beifen.name,
      })
    end
  end,
})

beifen:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(beifen.name) and
      player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
      player:getHandcardNum() > 2 * player:getMark("@shuangjia")
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

beifen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(beifen.name) and player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
      player:getHandcardNum() > 2 * #table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@shuangjia-inhand") > 0
      end)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(beifen.name) and player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
      player:getHandcardNum() > 2 * #table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@shuangjia-inhand") > 0
      end)
  end,
})

return beifen
