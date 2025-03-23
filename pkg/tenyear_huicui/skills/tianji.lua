local tianji = fk.CreateSkill {
  name = "tianji"
}

Fk:loadTranslationTable{
  ['tianji'] = '天机',
  [':tianji'] = '锁定技，生效后的判定牌进入弃牌堆后，你从牌堆随机获得与该牌类型、花色和点数相同的牌各一张。',
  ['$tianji1'] = '顺天而行，坐收其利。',
  ['$tianji2'] = '只可意会，不可言传。',
}

tianji:addEffect(fk.AfterCardsMove, {
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tianji.name) then
      local cards = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonJudge and move.skillName == "" then
          table.insertTableIfNeed(cards, table.map(move.moveInfo, function (info)
            return info.cardId
          end))
        end
      end
      if #cards > 0 then
        event:setCostData(skill, cards)
        return true
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local cards = table.simpleClone(event:getCostData(skill))
    for _, id in ipairs(cards) do
      if not player:hasSkill(tianji.name) then break end
      skill:doCost(event, target, player, {id = id})
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = data.id
    local cards = {}
    local card, card2 = Fk:getCardById(id, true)
    local cardMap = {{}, {}, {}}
    for _, id2 in ipairs(room.draw_pile) do
      card2 = Fk:getCardById(id2, true)
      if card2.type == card.type then
        table.insert(cardMap[1], id2)
      end
      if card2.suit == card.suit then
        table.insert(cardMap[2], id2)
      end
      if card2.number == card.number then
        table.insert(cardMap[3], id2)
      end
    end
    for _ = 1, 3, 1 do
      local x = #cardMap[1] + #cardMap[2] + #cardMap[3]
      if x == 0 then break end
      local index = math.random(x)
      for i = 1, 3, 1 do
        if index > #cardMap[i] then
          index = index - #cardMap[i]
        else
          id = cardMap[i][index]
          table.insert(cards, id)
          cardMap[i] = {}
          for _, v in ipairs(cardMap) do
            table.removeOne(v, id)
          end
          break
        end
      end
    end
    if #cards > 0 then
      room:moveCards{
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = tianji.name,
      }
    end
  end,
})

return tianji
