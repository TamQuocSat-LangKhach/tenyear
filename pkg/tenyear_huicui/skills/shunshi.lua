local shunshi = fk.CreateSkill {
  name = "shunshi",
}

Fk:loadTranslationTable{
  ["shunshi"] = "顺世",
  [":shunshi"] = "准备阶段或当你于回合外受到伤害后，你可以交给一名其他角色一张牌（伤害来源除外），然后直到你的回合结束，你摸牌阶段多摸一张牌、"..
  "出牌阶段使用【杀】次数上限+1、手牌上限+1。",

  ["#shunshi-invoke"] = "顺世：你可以交给一名其他角色一张牌，直到你的回合结束获得效果",
  ["@shunshi"] = "顺世",

  ["$shunshi1"] = "顺应时运，得保安康。",
  ["$shunshi2"] = "随遇而安，宠辱不惊。",
}

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, shunshi.name, nil, false, player)
    if not player.dead then
      room:addPlayerMark(player, "@shunshi", 1)
    end
  end,
}

shunshi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shunshi.name) and player.phase == Player.Start and
      not player:isNude() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      table.insert(targets, p.id)
    end
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = shunshi.name,
      prompt = "#shunshi-invoke",
      cancelable = true,
    })
    if #to > 0 and #cards > 0 then
      event:setCostData(self, {tos = to, cards = cards})
      return true
    end
  end,
  on_use = spec.on_use,
})

shunshi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shunshi.name) and
      not player:isNude() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p ~= data.from
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p ~= data.from
    end)
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = shunshi.name,
      prompt = "#shunshi-invoke",
      cancelable = true,
    })
    if #to > 0 and #cards > 0 then
      event:setCostData(self, {tos = to, cards = cards})
      return true
    end
  end,
  on_use = spec.on_use,
})

shunshi:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@shunshi", 0)
  end,
})

shunshi:addEffect(fk.DrawNCards, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@shunshi") > 0
  end,
  on_refresh = function(self, event, target, player, data)
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
