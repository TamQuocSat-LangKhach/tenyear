local ty__meibu = fk.CreateSkill {
  name = "ty__meibu"
}

Fk:loadTranslationTable{
  ['ty__meibu'] = '魅步',
  ['ty__zhixi'] = '止息',
  ['#ty__meibu-invoke'] = '魅步：你可以弃置一张牌，令 %dest 本回合获得〖止息〗',
  ['@ty__meibu-turn'] = '魅步',
  [':ty__meibu'] = '其他角色的出牌阶段开始时，若你在其攻击范围内，你可以弃置一张牌，令该角色于本回合内拥有〖止息〗。若其本回合因〖止息〗弃置牌的花色与你本次发动〖魅步〗弃置牌的花色相同，你获得之。',
  ['$ty__meibu1'] = '姐妹之情，当真今日了断？',
  ['$ty__meibu2'] = '上下和睦，姐妹同心。',
}

ty__meibu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(ty__meibu.name) then
      return target.phase == Player.Play and target ~= player and target:inMyAttackRange(player) and not player:isNude()
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ty__meibu.name,
      cancelable = true,
      prompt = "#ty__meibu-invoke::" .. target.id
    })
    if #card > 0 then
      event:setCostData(skill, card[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:setPlayerMark(player, "ty__meibu-turn", Fk:getCardById(event:getCostData(skill)).suit)
    room:throwCard({event:getCostData(skill)}, ty__meibu.name, player, player)
    if target.dead then return end
    room:setPlayerMark(target, "@ty__meibu-turn", Fk:getCardById(event:getCostData(skill)):getSuitString(true))
    local turn = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn ~= nil and not target:hasSkill("ty__zhixi", true) then
      room:handleAddLoseSkills(target, "ty__zhixi", nil, true, false)
      turn:addCleaner(function()
        room:handleAddLoseSkills(target, "-ty__zhixi", nil, true, false)
      end)
    end
  end,
})

ty__meibu:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty__meibu.name) and player:usedSkillTimes(ty__meibu.name, Player.HistoryTurn) > 0 then
      for _, move in ipairs(data) do
        if move.skillName == "ty__zhixi" then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).suit == player:getMark("ty__meibu-turn") and
              player.room:getCardArea(info.cardId) == Card.DiscardPile then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    for _, move in ipairs(data) do
      if move.skillName == "ty__zhixi" then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).suit == player:getMark("ty__meibu-turn") and
            room:getCardArea(info.cardId) == Card.DiscardPerve.DiscardPile then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end
    room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, ty__meibu.name, nil, true, player.id)
  end,
})

return ty__meibu
