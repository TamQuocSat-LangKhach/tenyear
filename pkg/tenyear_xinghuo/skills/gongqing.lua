local gongqing = fk.CreateSkill {
  name = "gongqing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["gongqing"] = "公清",
  [":gongqing"] = "锁定技，当你受到伤害时，若伤害来源的攻击范围小于3，将伤害值改为1；当你受到伤害时，若伤害来源的攻击范围大于3，你此伤害值+1。",

  ["$gongqing1"] = "尔辈何故与降虏交善。",
  ["$gongqing2"] = "豪将在外，增兵必成祸患啊！",
}

gongqing:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gongqing.name) and data.from and
      ((data.from:getAttackRange() < 3 and data.damage > 1) or data.from:getAttackRange() > 3)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from:getAttackRange() < 3 then
      data:changeDamage(1 - data.damage)
      player:broadcastSkillInvoke(gongqing.name, 1)
      room:notifySkillInvoked(player, gongqing.name, "defensive")
    elseif data.from:getAttackRange() > 3 then
      data:changeDamage(1)
      player:broadcastSkillInvoke(gongqing.name, 2)
      room:notifySkillInvoked(player, gongqing.name, "negative")
    end
  end,
})

return gongqing
