local shunshi = fk.CreateSkill {
  name = "shunshi"
}

Fk:loadTranslationTable{
  ['shunshi'] = '顺世',
  ['#shunshi-cost'] = '顺世：你可以交给一名其他角色一张牌，然后直到你的回合结束获得效果',
  ['@shunshi'] = '顺世',
  ['#shunshi_delay'] = '顺世',
  [':shunshi'] = '准备阶段或当你于回合外受到伤害后，你可以交给一名其他角色一张牌（伤害来源除外），然后直到你的回合结束，你：摸牌阶段多摸一张牌、出牌阶段使用的【杀】次数上限+1、手牌上限+1。',
  ['$shunshi1'] = '顺应时运，得保安康。',
  ['$shunshi2'] = '随遇而安，宠辱不惊。',
}

shunshi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shunshi) and not player:isNude() then
      return player.phase == Player.Start
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      table.insert(targets, p.id)
    end
    local tos, id = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = targets,
      min_target_num = 1,
      max_target_num = 1,
      pattern = ".",
      prompt = "#shunshi-cost",
      skill_name = shunshi.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, {tos[1], id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self)[2], Card.PlayerHand, room:getPlayerById(event:getCostData(self)[1]), fk.ReasonGive, shunshi.name, nil, false, player.id)
    if not player.dead then
      room:addPlayerMark(player, "@shunshi", 1)
    end
  end,
})

shunshi:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shunshi) and not player:isNude() then
      return player ~= player.room.current
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if p ~= data.from then
        table.insert(targets, p.id)
      end
    end
    local tos, id = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = targets,
      min_target_num = 1,
      max_target_num = 1,
      pattern = ".",
      prompt = "#shunshi-cost",
      skill_name = shunshi.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, {tos[1], id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self)[2], Card.PlayerHand, room:getPlayerById(event:getCostData(self)[1]), fk.ReasonGive, shunshi.name, nil, false, player.id)
    if not player.dead then
      room:addPlayerMark(player, "@shunshi", 1)
    end
  end,
})

shunshi:addEffect(fk.AfterTurnEnd, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@shunshi") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@shunshi", 0)
  end,
})

shunshi:addEffect(fk.DrawNCards, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@shunshi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@shunshi")
  end,
})

shunshi:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@shunshi")
    end
  end,
})

shunshi:addEffect("maxcards", {
  correct_func = function(self, player)
    return player:getMark("@shunshi")
  end,
})

return shunshi
