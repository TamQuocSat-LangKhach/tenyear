local skill = fk.CreateSkill {
  name = "#poisonous_dagger_skill",
  attached_equip = "poisonous_dagger",
}

Fk:loadTranslationTable{
  ["#poisonous_dagger_skill"] = "混毒弯匕",
  ["#poisonous_dagger-invoke"] = "混毒弯匕：你可以令 %dest 失去%arg点体力",
}

skill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash" and
      not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#poisonous_dagger-invoke::"..data.to.id..":"..math.min(player:usedSkillTimes(skill.name, Player.HistoryTurn) + 1, 5)
    }) then
      event:setCostData(self, { tos = {data.to} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, math.min(player:usedSkillTimes(skill.name, Player.HistoryTurn), 5), skill.name)
  end,
})

return skill
