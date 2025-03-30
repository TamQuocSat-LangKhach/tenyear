local kaiji = fk.CreateSkill {
  name = "ty__kaiji",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["ty__kaiji"] = "开济",
  [":ty__kaiji"] = "转换技，出牌阶段限一次，阳：你可以摸体力上限张数的牌；阴：你可以弃置至多体力上限张数的牌（至少一张）。",

  ["#ty__kaiji-yang"] = "开济：你可以摸%arg张牌",
  ["#ty__kaiji-yin"] = "开济：你可以弃置至多%arg张牌",

  ["$ty__kaiji1"] = "谋虑渊深，料远若近。",
  ["$ty__kaiji2"] = "视昧而察，筹不虚运。",
}

kaiji:addEffect("active", {
  anim_type = "switch",
  min_card_num = function (self, player)
    if player:getSwitchSkillState(kaiji.name, false) == fk.SwitchYang then
      return 0
    else
      return 1
    end
  end,
  max_card_num = function (self, player)
    if player:getSwitchSkillState(kaiji.name, false) == fk.SwitchYang then
      return 0
    else
      return player.maxHp
    end
  end,
  target_num = 0,
  prompt = function (self, player)
    return "#ty__kaiji-"..player:getSwitchSkillState(kaiji.name, false, true)..":::"..player.maxHp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(kaiji.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if player:getSwitchSkillState(kaiji.name, false) == fk.SwitchYang then
      return false
    else
      return #selected < player.maxHp and not player:prohibitDiscard(to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if player:getSwitchSkillState(kaiji.name, true) == fk.SwitchYang then
      player:drawCards(player.maxHp, kaiji.name)
    else
      room:throwCard(effect.cards, kaiji.name, player, player)
    end
  end,
})

return kaiji
