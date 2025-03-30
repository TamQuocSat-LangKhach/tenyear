local jieyingh = fk.CreateSkill {
  name = "jieyingh",
}

Fk:loadTranslationTable{
  ["jieyingh"] = "节应",
  [":jieyingh"] = "结束阶段，你可以选择一名其他角色，然后该角色的下回合内：其使用【杀】或普通锦囊牌无距离限制，若仅指定一个目标则可以"..
  "多指定一个目标；当其造成伤害后，其不能再使用牌直到回合结束。",

  ["#jieyingh-choose"] = "节应：选择一名角色，其下个回合使用牌无距离限制且可多指定一个目标，造成伤害后不能使用牌",
  ["@jieyingh-turn"] = "节应",
  ["#jieyingh-extra"] = "节应：你可为此%arg额外指定1个目标",
  ["jieyingh_prohibit"] = "禁止出牌",

  ["$jieyingh1"] = "秉志持节，应时而动。",
  ["$jieyingh2"] = "授节于汝，随机应变！",
}

jieyingh:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jieyingh.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#jieyingh-choose",
      skill_name = jieyingh.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(event:getCostData(self).tos[1], jieyingh.name, 1)
  end,
})

jieyingh:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark(jieyingh.name) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, jieyingh.name, 0)
    room:setPlayerMark(player, "@jieyingh-turn", 1)
  end,
})

jieyingh:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@jieyingh-turn") ~= 0 and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      data:isOnlyTarget(data.tos[1]) and #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = data:getExtraTargets(),
      min_num = 1,
      max_num = 1,
      prompt = "#jieyingh-extra:::"..data.card:toLogString(),
      skill_name = jieyingh.name,
    })
    if #to > 0 then
    event:setCostData(self, {tos = to})
    return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})

jieyingh:addEffect(fk.Damage, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@jieyingh-turn") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@jieyingh-turn", "jieyingh_prohibit")
  end,
})

jieyingh:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    return card and (card:isCommonTrick() or card.trueName == "slash") and player:getMark("@jieyingh-turn") ~= 0
  end,
})

jieyingh:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and player:getMark("@jieyingh-turn") == "jieyingh_prohibit"
  end,
})

return jieyingh
