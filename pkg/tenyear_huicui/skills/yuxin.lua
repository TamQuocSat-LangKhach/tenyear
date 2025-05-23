local yuxin = fk.CreateSkill {
  name = "yuxin",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["yuxin"] = "御心",
  [":yuxin"] = "限定技，当一名角色进入濒死状态时，你可以令其回复体力至X点（X为你的体力值且至少为1）。",

  ["#yuxin-invoke"] = "御心：是否令 %dest 回复体力至%arg？",

  ["$yuxin1"] = "得一人知情识趣，何妨同甘共苦。",
  ["$yuxin2"] = "临千军而不改其静，御心无波尔。",
}

yuxin:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuxin.name) and player:usedSkillTimes(yuxin.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yuxin.name,
      prompt = "#yuxin-invoke::"..target.id..":"..math.max(1, player.hp),
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover {
      who = target,
      num = math.max(1, player.hp) - target.hp,
      recoverBy = player,
      skillName = yuxin.name,
    }
  end,
})

return yuxin
