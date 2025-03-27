local ty__niaoxiang = fk.CreateSkill {
  name = "ty__niaoxiang"
}

Fk:loadTranslationTable{
  ['ty__niaoxiang'] = '鸟翔',
  [':ty__niaoxiang'] = '锁定技，当你使用【杀】指定目标后，若你在其攻击范围内，其响应此【杀】的方式改为依次使用两张【闪】。',
  ['$ty__niaoxiang1'] = '此战，必是有死无生！',
  ['$ty__niaoxiang2'] = '抢占先机，占尽优势！'
}

ty__niaoxiang:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card.trueName == "slash" and
      player.room:getPlayerById(data.to):inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    data.fixedResponseTimes = data.fixedResponseTimes or {}
    data.fixedResponseTimes["jink"] = 2
  end,
})

return ty__niaoxiang
