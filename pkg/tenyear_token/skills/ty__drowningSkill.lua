local ty__drowningSkill = fk.CreateSkill {
  name = "ty__drowning_skill"
}

Fk:loadTranslationTable{
  ['ty__drowning_skill'] = '水淹七军',
  ['#ty__drowning_skill'] = '选择1-2名目标角色，第一名角色受到1点雷电伤害并摸牌，第二名角色受到1点雷电伤害并弃牌',
}

ty__drowningSkill:addEffect('active', {
  min_target_num = 1,
  max_target_num = 2,
  mod_target_filter = Util.TrueFunc,
  target_filter = Util.TargetFilter,
  on_use = function(self, room, cardUseEvent)
    if cardUseEvent.tos == nil or #cardUseEvent.tos == 0 then return end
    cardUseEvent.extra_data = cardUseEvent.extra_data or {}
    cardUseEvent.extra_data.firstTargetOfTYDrowning = cardUseEvent.tos[1][1]
  end,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    room:damage({
      from = from,
      to = to,
      card = effect.card,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = ty__drowning_skill.name
    })
    if not to.dead then
      if effect.extra_data and effect.extra_data.firstTargetOfTYDrowning == effect.to then
        room:askToDiscard(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = ty__drowning_skill.name,
          cancelable = false,
        })
      else
        to:drawCards(1, ty__drowning_skill.name)
      end
    end
  end,
})

return ty__drowningSkill
