local aishou = fk.CreateSkill {
  name = "aishou"
}

Fk:loadTranslationTable{
  ['aishou'] = '隘守',
  ['@@aishou-inhand'] = '隘',
  [':aishou'] = '结束阶段，你可以摸X张牌（X为你的体力上限），这些牌标记为“隘”。当你于回合外失去最后一张“隘”后，你减1点体力上限。<br>准备阶段，弃置你手牌中的所有“隘”，若弃置的“隘”数大于你的体力值，你加1点体力上限。',
  ['$aishou1'] = '某家未闻有一合而破关之将。',
  ['$aishou2'] = '凭关而守，敌强又奈何？',
}

aishou:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(aishou.name) then
      if target == player and (player.phase == Player.Finish or 
        (player.phase == Player.Start and table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 end)))) then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player)
    if player.phase == Player.Finish then
      return player.room:askToSkillInvoke(player, { skill_name = aishou.name })
    end
    return true
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(aishou.name)
    if player.phase == Player.Finish then
      room:notifySkillInvoked(player, aishou.name, "drawcard")
      player:drawCards(player.maxHp, aishou.name, nil, "@@aishou-inhand")
    else
      room:notifySkillInvoked(player, aishou.name, "special")
      local cards = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 end)
      room:throwCard(cards, aishou.name, player, player)
      if not player.dead and #cards > player.hp then
        room:changeMaxHp(player, 1)
      end
    end
  end,
})

aishou:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player.phase == Player.NotActive and 
      not table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 end) then
      for _, move in ipairs(data) do
        if move.from == player.id and (move.extra_data and move.extra_data.aishou) then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:notifySkillInvoked(player, aishou.name, "negative")
    room:changeMaxHp(player, -1)
  end,
})

aishou:addEffect(fk.BeforeCardsMove, {
  can_refresh = function (skill, event, target, player, data)
    return player:hasSkill(aishou.name) and player.phase == Player.NotActive
  end,
  on_refresh = function (skill, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@aishou-inhand") > 0 then
            move.extra_data = move.extra_data or {}
            move.extra_data.aishou = true
            break
          end
        end
      end
    end
  end,
})

return aishou
