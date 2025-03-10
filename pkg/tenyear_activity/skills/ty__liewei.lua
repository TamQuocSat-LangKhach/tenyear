local ty__liewei = fk.CreateSkill {
  name = "ty__liewei"
}

Fk:loadTranslationTable{
  ['ty__liewei'] = '裂围',
  [':ty__liewei'] = '每回合限X次（X为你的体力值，你的回合内无此限制），有角色进入濒死状态时，你可以摸一张牌。',
  ['$ty__liewei1'] = '都给我交出来！',
  ['$ty__liewei2'] = '还有点用，暂且饶你一命！',
}

ty__liewei:addEffect(fk.EnterDying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(ty__liewei.name) and
      (player.phase ~= Player.NotActive or player:usedSkillTimes(ty__liewei.name) < player.hp)
  end,
  on_use = function(self, event, target, player)
    player:drawCards(1, ty__liewei.name)
  end,
})

return ty__liewei
