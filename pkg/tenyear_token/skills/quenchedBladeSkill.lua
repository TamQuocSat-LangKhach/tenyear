local quenchedBladeSkill = fk.CreateSkill {
  name = "#quenched_blade_skill",
}

Fk:loadTranslationTable{
  ['#quenched_blade_skill'] = '烈淬刀',
  ['quenched_blade'] = '烈淬刀',
  ['#quenched_blade-invoke'] = '烈淬刀：你可以弃置一张牌，令你对 %dest 造成的伤害+1',
}

quenchedBladeSkill:addEffect(fk.DamageCaused, {
  attached_equip = "quenched_blade",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(quenchedBladeSkill) and data.card and data.card.trueName == "slash" and not player:isNude()
      and player.room.logic:damageByCardEffect() and player:usedSkillTimes(quenchedBladeSkill.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = quenchedBladeSkill.name,
      cancelable = true,
      pattern = ".|.|.|.|.|.|^" .. tostring(player:getEquipment(Card.SubtypeWeapon)),
      prompt = "#quenched_blade-invoke::" .. data.to.id,
    })
    if #cards > 0 then
      event:setCostData(self, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self), quenchedBladeSkill.name, player, player)
    data.damage = data.damage + 1
  end,
})

quenchedBladeSkill:addEffect('targetmod', {
  attached_equip = "quenched_blade",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(quenchedBladeSkill) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return 1
    end
  end,
})

return quenchedBladeSkill
