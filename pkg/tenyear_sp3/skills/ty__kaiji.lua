local ty__kaiji = fk.CreateSkill {
  name = "ty__kaiji"
}

Fk:loadTranslationTable{
  ['ty__kaiji'] = '开济',
  [':ty__kaiji'] = '转换技，出牌阶段限一次，阳：你可以摸体力上限张数的牌；阴：你可以弃置至多体力上限张数的牌（至少一张）。',
  ['$ty__kaiji1'] = '谋虑渊深，料远若近。',
  ['$ty__kaiji2'] = '视昧而察，筹不虚运。',
}

ty__kaiji:addEffect('active', {
  anim_type = "switch",
  switch_skill_name = "ty__kaiji",
  min_card_num = function (player)
    if player:getSwitchSkillState("ty__kaiji", false) == fk.SwitchYang then
      return 0
    else
      return 1
    end
  end,
  max_card_num = function (player)
    if player:getSwitchSkillState("ty__kaiji", false) == fk.SwitchYang then
      return 0
    else
      return player.maxHp
    end
  end,
  target_num = 0,
  prompt = function (player)
    return "#ty__kaiji-"..player:getSwitchSkillState("ty__kaiji", false, true)..":::"..player.maxHp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(ty__kaiji.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if player:getSwitchSkillState(ty__kaiji.name, false) == fk.SwitchYang then
      return false
    else
      return #selected < player.maxHp and not player:prohibitDiscard(to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(ty__kaiji.name, true) == fk.SwitchYang then
      player:drawCards(player.maxHp, ty__kaiji.name)
    else
      room:throwCard(effect.cards, ty__kaiji.name, player, player)
    end
  end,
})

return ty__kaiji
