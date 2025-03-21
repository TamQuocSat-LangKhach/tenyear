local ty__jieying = fk.CreateSkill {
  name = "ty__jieying"
}

Fk:loadTranslationTable{
  ['ty__jieying'] = '节应',
  ['#ty__jieying-choose'] = '节应：选择一名其他角色，令其下个回合<br>使用牌无距离限制且可多指定1个目标，造成伤害后不能使用牌',
  ['@ty__jieying'] = '节应',
  ['#ty__jieying_delay'] = '节应',
  ['#ty__jieying-extra'] = '节应：可为此【%arg】额外指定1个目标',
  ['ty__jieying_prohibit'] = '不能出牌',
  [':ty__jieying'] = '结束阶段，你可以选择一名其他角色，然后该角色的下回合内：其使用【杀】或普通锦囊牌无距离限制，若仅指定一个目标则可以多指定一个目标；当其造成伤害后，其不能再使用牌直到回合结束。',
  ['$ty__jieying1'] = '秉志持节，应时而动。',
  ['$ty__jieying2'] = '授节于汝，随机应变！',
}

ty__jieying:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__jieying.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__jieying-choose",
      skill_name = ty__jieying.name,
    })
    if #tos > 0 then
      event:setCostData(skill, tos[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player.room:getPlayerById(event:getCostData(skill)), "@ty__jieying", {})
  end,
})

ty__jieying:addEffect({fk.AfterCardTargetDeclared, fk.Damage}, {
  name = "#ty__jieying_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= target or player.dead or player:getMark("@ty__jieying") == 0 or player.phase == Player.NotActive then return false end
    if event == fk.AfterCardTargetDeclared then
      return (data.card:isCommonTrick() or data.card.trueName == "slash") and #TargetGroup:getRealTargets(data.tos) == 1
    elseif event == fk.Damage then
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardTargetDeclared then
      local tos = room:askToChoosePlayers(player, {
        targets = room:getUseExtraTargets(data),
        min_num = 1,
        max_num = 1,
        prompt = "#ty__jieying-extra:::"..data.card:toLogString(),
        skill_name = ty__jieying.name
      })
      if #tos == 1 then
        table.insert(data.tos, tos)
      end
    elseif event == fk.Damage then
      room:setPlayerMark(player, "@ty__jieying", {"ty__jieying_prohibit"})
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@ty__jieying") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty__jieying", 0)
  end,
})

ty__jieying:addEffect("targetmod", {
  name = "#ty__jieying_targetmod",
  bypass_distances = function(self, player, skill, card)
    return card and (card:isCommonTrick() or card.trueName == "slash") and player:getMark("@ty__jieying") ~= 0 and player.phase ~= Player.NotActive
  end,
})

ty__jieying:addEffect("prohibit", {
  name = "#ty__jieying_prohibit",
  prohibit_use = function(self, player, card)
    return type(player:getMark("@ty__jieying")) == "table" and table.contains(player:getMark("@ty__jieying"), "ty__jieying_prohibit")
  end,
})

return ty__jieying
