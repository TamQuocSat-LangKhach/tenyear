local yizu = fk.CreateSkill {
  name = "yizu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yizu"] = "轶祖",
  [":yizu"] = "锁定技，每回合限一次，当你成为【杀】或【决斗】的目标后，若你的体力值不大于使用者的体力值，你回复1点体力。",

  ["$yizu1"] = "仿祖父行事，可阻敌袭。",
  ["$yizu2"] = "习先人故智，可御寇侵。",
}

yizu:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yizu.name) and
      table.contains({"slash", "duel"}, data.card.trueName) and
      data.from.hp >= player.hp and player:isWounded() and
      player:usedSkillTimes(yizu.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = yizu.name,
    }
  end,
})

return yizu
