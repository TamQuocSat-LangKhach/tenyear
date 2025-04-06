local moucheng = fk.CreateSkill {
  name = "ty__moucheng",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ty__moucheng"] = "谋逞",
  [":ty__moucheng"] = "觉醒技，准备阶段，若你发动〖连计〗的两个选项都被选择过，则你失去〖连计〗，获得〖矜功〗。",

  ["$ty__moucheng1"] = "除贼安国，利于天下。",
  ["$ty__moucheng2"] = "董贼已擒，长安可兴。",
}

moucheng:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(moucheng.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(moucheng.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("ty__lianji1") > 0 and player:getMark("ty__lianji2") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-ty__lianji|jingong")
  end,
})

return moucheng
