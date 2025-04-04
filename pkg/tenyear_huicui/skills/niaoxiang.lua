local niaoxiang = fk.CreateSkill {
  name = "ty__niaoxiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__niaoxiang"] = "鸟翔",
  [":ty__niaoxiang"] = "锁定技，当你使用【杀】指定目标后，若你在其攻击范围内，其响应此【杀】的方式改为依次使用两张【闪】。",

  ["$ty__niaoxiang1"] = "此战，必是有死无生！",
  ["$ty__niaoxiang2"] = "抢占先机，占尽优势！"
}

niaoxiang:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(niaoxiang.name) and data.card.trueName == "slash" and
    data.to:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    data.fixedResponseTimes = 2
    data.fixedAddTimesResponsors = data.fixedAddTimesResponsors or {}
    table.insertIfNeed(data.fixedAddTimesResponsors, data.to)
  end,
})

return niaoxiang
