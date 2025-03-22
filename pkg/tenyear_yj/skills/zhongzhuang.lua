local zhongzhuang = fk.CreateSkill {
  name = "zhongzhuang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhongzhuang"] = "忠壮",
  [":zhongzhuang"] = "锁定技，你使用【杀】造成伤害时，若你的攻击范围大于3，则此伤害+1；若你的攻击范围小于3，则此伤害改为1。",

  ["$zhongzhuang1"] = "秽尘天听，卿有不测之祸！",
  ["$zhongzhuang2"] = "倾乱国政，安得寿终正寝？",
}

zhongzhuang:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhongzhuang.name) and
      data.card and data.card.trueName == "slash" and player.room.logic:damageByCardEffect(false) and
      (player:getAttackRange() > 3 or (player:getAttackRange() < 3 and data.damage > 1))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getAttackRange() > 3 then
      data:changeDamage(1)
      player:broadcastSkillInvoke(zhongzhuang.name, 1)
      room:notifySkillInvoked(player, zhongzhuang.name, "offensive")
    elseif player:getAttackRange() < 3 then
      data:changeDamage(1 - data.damage)
      player:broadcastSkillInvoke(zhongzhuang.name, 2)
      room:notifySkillInvoked(player, zhongzhuang.name, "negative")
    end
  end,
})

return zhongzhuang
