local meibu = fk.CreateSkill{
  name = "ty__meibu",
}

Fk:loadTranslationTable{
  ["ty__meibu"] = "魅步",
  [":ty__meibu"] = "其他角色的出牌阶段开始时，若你在其攻击范围内，你可以弃置一张牌，令该角色于本回合内拥有〖止息〗。若其本回合因〖止息〗"..
  "弃置牌的花色与你本次发动〖魅步〗弃置牌的花色相同，你获得之。",

  ["#ty__meibu-invoke"] = "魅步：是否弃一张牌，令 %dest 本回合获得“止息”？",
  ["@ty__meibu_src-turn"] = "魅步",

  ["$ty__meibu1"] = "姐妹之情，当真今日了断？",
  ["$ty__meibu2"] = "上下和睦，姐妹同心。",
}

meibu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(meibu.name) and target.phase == Player.Play and
      target:inMyAttackRange(player) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = meibu.name,
      prompt = "#ty__meibu-invoke::"..target.id,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(event:getCostData(self).cards[1])
    room:addTableMarkIfNeed(player, "@ty__meibu_src-turn", card:getSuitString(true))
    room:throwCard(card, meibu.name, player, player)
    if target.dead then return end
    room:setPlayerMark(target, "ty__meibu-turn", 1)
    room:handleAddLoseSkills(target, "ty__zhixi")
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(target, "-ty__zhixi")
    end)
  end,
})

meibu:addEffect("distance", {
  fixed_func = function(self, from, to)
    if from:getMark("ty__meibu-turn") > 0 and to:getMark("@ty__meibu_src-turn") ~= 0 then
      return 1
    end
  end,
})

meibu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@ty__meibu_src-turn") ~= 0 then
      for _, move in ipairs(data) do
        if move.skillName == "ty__zhixi" then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getTableMark("@ty__meibu_src-turn"), Fk:getCardById(info.cardId):getSuitString(true)) and
              player.room:getCardArea(info.cardId) == Card.DiscardPile then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.skillName == "ty__zhixi" then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getTableMark("@ty__meibu_src-turn"), Fk:getCardById(info.cardId):getSuitString(true)) and
            player.room:getCardArea(info.cardId) == Card.DiscardPile then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end
    player.room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, meibu.name, nil, true, player)
  end,
})

return meibu
