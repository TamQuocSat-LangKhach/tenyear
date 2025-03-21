local qingjiao = fk.CreateSkill {
  name = "qingjiao"
}

Fk:loadTranslationTable{
  ['qingjiao'] = '清剿',
  [':qingjiao'] = '出牌阶段开始时，你可以弃置所有手牌，然后从牌堆或弃牌堆中随机获得八张牌名各不相同且副类别不同的牌。若如此做，结束阶段，你弃置所有牌。',
  ['$qingjiao1'] = '慈不掌兵，义不养财！',
  ['$qingjiao2'] = '清蛮夷之乱，剿不臣之贼！',
}

qingjiao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingjiao.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("h")

    local wholeCards = table.clone(room.draw_pile)
    table.insertTable(wholeCards, room.discard_pile)

    local cardSubtypeStrings = {
      [Card.SubtypeWeapon] = "weapon",
      [Card.SubtypeArmor] = "armor",
      [Card.SubtypeDefensiveRide] = "defensive_horse",
      [Card.SubtypeOffensiveRide] = "offensive_horse",
      [Card.SubtypeTreasure] = "treasure",
    }

    local cardDic = {}
    for _, id in ipairs(wholeCards) do
      local card = Fk:getCardById(id)
      local cardName = card.type == Card.TypeEquip and cardSubtypeStrings[card.sub_type] or card.trueName
      cardDic[cardName] = cardDic[cardName] or {}
      table.insert(cardDic[cardName], id)
    end

    local toObtain = {}
    while #toObtain < 8 and next(cardDic) ~= nil do
      local dicLength = 0
      for _, ids in pairs(cardDic) do
        dicLength = dicLength + #ids
      end

      local randomIdx = math.random(1, dicLength)
      dicLength = 0
      for cardName, ids in pairs(cardDic) do
        dicLength = dicLength + #ids
        if dicLength >= randomIdx then
          table.insert(toObtain, ids[dicLength - randomIdx + 1])
          cardDic[cardName] = nil
          break
        end
      end
    end

    if #toObtain > 0 then
      room:moveCards({
        ids = toObtain,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = qingjiao.name,
      })
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:usedSkillTimes(qingjiao.name, Player.HistoryTurn) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player:throwAllCards("he")
  end,
})

return qingjiao
