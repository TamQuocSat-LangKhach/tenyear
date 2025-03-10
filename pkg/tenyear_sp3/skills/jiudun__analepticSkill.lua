local jiudun__analepticSkill = fk.CreateSkill {
  name = "jiudun__analepticSkill"
}

Fk:loadTranslationTable {
  ['@jiudun_drank'] = '酒',
}

jiudun__analepticSkill:addEffect('active', {
  prompt = "#analeptic_skill",
  max_turn_use_time = 1,
  mod_target_filter = jd_analeptic.skill.modTargetFilter,
  can_use = jd_analeptic.skill.canUse,
  on_use = jd_analeptic.skill.onUse,
  on_effect = function(_, room, effect)
    local to = room:getPlayerById(effect.to)
    if to.dead then return end
    if effect.extra_data and effect.extra_data.analepticRecover then
      room:recover({
        who = to,
        num = 1,
        recoverBy = room:getPlayerById(effect.from),
        card = effect.card,
      })
    else
      room:addPlayerMark(to, "@jiudun_drank", 1 + ((effect.extra_data or {}).additionalDrank or 0))
    end
  end,
})

return jiudun__analepticSkill
