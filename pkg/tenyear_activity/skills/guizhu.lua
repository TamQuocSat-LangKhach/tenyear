local guizhu = fk.CreateSkill {
  name = "guizhu"
}

Fk:loadTranslationTable{
  ['guizhu'] = '鬼助',
  [':guizhu'] = '每回合限一次，当一名角色进入濒死状态时，你可以摸两张牌。',
}

guizhu:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guizhu.name) and player:usedSkillTimes(guizhu.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    if room:askToSkillInvoke(player, {skill_name = guizhu.name}) then
      player:drawCards(2, guizhu.name)
    end
  end,
})

return guizhu
