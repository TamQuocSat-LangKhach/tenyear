local yinjun = fk.CreateSkill {
  name = "yinjun"
}

Fk:loadTranslationTable{
  ['yinjun'] = '寅君',
  ['#yinjun-invoke'] = '寅君：你可以视为对 %dest 使用【杀】',
  [':yinjun'] = '当你对其他角色从手牌使用指定唯一目标的【杀】或锦囊牌结算后，你可以视为对其使用一张【杀】（此【杀】伤害无来源）。若本回合发动次数大于你当前体力值，此技能本回合无效。',
  ['$yinjun1'] = '既乘虎豹之威，当弘大魏万年。',
  ['$yinjun2'] = '今日青锋在手，可驯四方虎狼。',
}

yinjun:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(yinjun) and data.tos and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and
      #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id and
      player:getMark("yinjun_fail-turn") == 0 then
      if U.IsUsingHandcard(player, data) then
        local to = player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
        local card = Fk:cloneCard("slash")
        card.skillName = yinjun.name
        return not to.dead and not player:prohibitUse(card) and not player:isProhibited(to, card)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yinjun.name,
      prompt = "#yinjun-invoke::" .. TargetGroup:getRealTargets(data.tos)[1]
    })
  end,
  on_use = function(self, event, target, player, data)
    local use = {
      from = player.id,
      tos = {TargetGroup:getRealTargets(data.tos)},
      card = Fk:cloneCard("slash"),
      extraUse = true,
    }
    use.card.skillName = yinjun.name
    player.room:useCard(use)
    if not player.dead and player:usedSkillTimes(yinjun.name, Player.HistoryTurn) > player.hp then
      player.room:setPlayerMark(player, "yinjun_fail-turn", 1)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return data.card and table.contains(data.card.skillNames, yinjun.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.from = nil
  end,
})

return yinjun
