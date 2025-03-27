local yinjun = fk.CreateSkill {
  name = "yinjun",
}

Fk:loadTranslationTable{
  ["yinjun"] = "寅君",
  [":yinjun"] = "当你对其他角色从手牌使用指定唯一目标的【杀】或锦囊牌结算后，你可以视为对其使用一张【杀】（此【杀】伤害无来源）。"..
  "若本回合发动次数大于你当前体力值，此技能本回合无效。",

  ["#yinjun-invoke"] = "寅君：你可以视为对 %dest 使用【杀】",

  ["$yinjun1"] = "既乘虎豹之威，当弘大魏万年。",
  ["$yinjun2"] = "今日青锋在手，可驯四方虎狼。",
}

yinjun:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yinjun.name) and data.tos and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and data:IsUsingHandcard(player) and
      data.tos[1] ~= player and data:isOnlyTarget(data.tos[1]) and not data.tos[1].dead and
      not player:prohibitUse(Fk:cloneCard("slash")) and not player:isProhibited(data.tos[1], Fk:cloneCard("slash"))
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yinjun.name,
      prompt = "#yinjun-invoke::"..data.tos[1].id,
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("slash", nil, player, data.tos[1], yinjun.name, true)
    if not player.dead and player:usedSkillTimes(yinjun.name, Player.HistoryTurn) > player.hp then
      player.room:invalidateSkill(player, yinjun.name, "-turn")
    end
  end,
})
yinjun:addEffect(fk.PreDamage, {
  can_refresh = function(self, event, target, player, data)
    return data.card and table.contains(data.card.skillNames, yinjun.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.from = nil
  end,
})

return yinjun
