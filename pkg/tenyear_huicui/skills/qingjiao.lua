local qingjiao = fk.CreateSkill {
  name = "qingjiao",
}

Fk:loadTranslationTable{
  ["qingjiao"] = "清剿",
  [":qingjiao"] = "出牌阶段开始时，你可以弃置所有手牌，然后从牌堆或弃牌堆中随机获得八张牌名各不相同且副类别不同的牌。若如此做，结束阶段，"..
  "你弃置所有牌。",

  ["$qingjiao1"] = "慈不掌兵，义不养财！",
  ["$qingjiao2"] = "清蛮夷之乱，剿不臣之贼！",
}

qingjiao:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingjiao.name) and player.phase == Player.Play and
      not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("h", qingjiao.name)
    if player.dead then return end

    local all_cards = table.simpleClone(room.draw_pile)
    table.insertTable(all_cards, room.discard_pile)

    local cardSubtypeStrings = {
      [Card.SubtypeWeapon] = "weapon",
      [Card.SubtypeArmor] = "armor",
      [Card.SubtypeDefensiveRide] = "defensive_horse",
      [Card.SubtypeOffensiveRide] = "offensive_horse",
      [Card.SubtypeTreasure] = "treasure",
    }

    local dat = {}
    for _, id in ipairs(all_cards) do
      local card = Fk:getCardById(id)
      local name = card.type == Card.TypeEquip and cardSubtypeStrings[card.sub_type] or card.trueName
      dat[name] = dat[name] or {}
      table.insert(dat[name], id)
    end

    local cards = {}
    while #cards < 8 and next(dat) ~= nil do
      local dicLength = 0
      for _, ids in pairs(dat) do
        dicLength = dicLength + #ids
      end

      local index = math.random(1, dicLength)
      dicLength = 0
      for name, ids in pairs(dat) do
        dicLength = dicLength + #ids
        if dicLength >= index then
          table.insert(cards, ids[dicLength - index + 1])
          dat[name] = nil
          break
        end
      end
    end

    if #cards > 0 then
      room:moveCards{
        ids = cards,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = qingjiao.name,
      }
    end
  end,
})

qingjiao:addEffect(fk.EventPhaseStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and
      player:usedSkillTimes(qingjiao.name, Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    player:throwAllCards("he", qingjiao.name)
  end,
})

return qingjiao
