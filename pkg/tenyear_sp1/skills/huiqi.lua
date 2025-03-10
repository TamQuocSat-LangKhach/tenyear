local huiqi = fk.CreateSkill {
  name = "ty__huiqi"
}

Fk:loadTranslationTable{
  ['ty__huiqi'] = '彗企',
  ['ty__xieju'] = '偕举',
  [':ty__huiqi'] = '觉醒技，一名角色的回合结束时，若本回合成为过牌的目标的角色数为3且其中一名为你，你获得技能“偕举”，然后你执行一个额外的回合。',
  ['$ty__huiqi1'] = '老夫企踵西望，在殿奸邪可击。',
  ['$ty__huiqi2'] = '司马氏祸国乱政，天之所以殃之。',
}

huiqi:addEffect(fk.TurnEnd, {
  frequency = Skill.Wake,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(huiqi) and player:usedSkillTimes(huiqi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player)
    local room = player.room
    local targets = {}
    local events = room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
        table.insertIfNeed(targets, id)
      end
    end, Player.HistoryTurn)
    return #targets == 3 and table.contains(targets, player.id)
  end,
  on_use = function(self, event, target, player)
    player.room:handleAddLoseSkills(player, "ty__xieju")
    player:gainAnExtraTurn(true, huiqi.name)
  end,
})

return huiqi
