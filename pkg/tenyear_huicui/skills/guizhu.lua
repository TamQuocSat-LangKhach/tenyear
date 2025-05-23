local guizhu = fk.CreateSkill {
  name = "guizhu",
}

Fk:loadTranslationTable{
  ["guizhu"] = "鬼助",
  [":guizhu"] = "每回合限一次，当一名角色进入濒死状态时，你可以摸两张牌。",
}

guizhu:addEffect(fk.EnterDying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guizhu.name) and player:usedSkillTimes(guizhu.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, guizhu.name)
  end,
})

return guizhu
