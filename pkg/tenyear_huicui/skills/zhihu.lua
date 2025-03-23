local zhihu = fk.CreateSkill {
  name = "zhihu"
}

Fk:loadTranslationTable{
  ['zhihu'] = '执笏',
  [':zhihu'] = '锁定技，每回合限两次，当你对其他角色造成伤害后，你摸两张牌。',
}

zhihu:addEffect(fk.Damage, {
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(zhihu.name) and player:usedSkillTimes(zhihu.name, Player.HistoryTurn) < 2 and player ~= data.to
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, zhihu.name)
  end,
})

return zhihu
