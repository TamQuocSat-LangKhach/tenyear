local poisonousDaggerSkill = fk.CreateSkill {
  name = "#poisonous_dagger_skill"
}

Fk:loadTranslationTable{
  ['#poisonous_dagger_skill'] = '混毒弯匕',
  ['poisonous_dagger'] = '混毒弯匕',
  ['#poisonous_dagger-invoke'] = '混毒弯匕：你可以令 %dest 失去%arg点体力',
}

poisonousDaggerSkill:addEffect(fk.TargetSpecified, {
  attached_equip = "poisonous_dagger",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(poisonousDaggerSkill.name) and data.card and data.card.trueName == "slash" and
      not player.room:getPlayerById(data.to).dead
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = poisonousDaggerSkill.name,
      prompt = "#poisonous_dagger-invoke::"..data.to..":"..math.min(player:usedSkillTimes(poisonousDaggerSkill.name, Player.HistoryTurn) + 1, 5)
    }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(room:getPlayerById(event:getCostData(self).tos[1]), math.min(player:usedSkillTimes(poisonousDaggerSkill.name, Player.HistoryTurn), 5), poisonousDaggerSkill.name)
  end,
})

return poisonousDaggerSkill
