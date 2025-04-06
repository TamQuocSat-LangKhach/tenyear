local skill = fk.CreateSkill {
  name = "#quenched_blade_skill",
  attached_equip = "quenched_blade",
}

Fk:loadTranslationTable{
  ["#quenched_blade_skill"] = "烈淬刀",
  ["#quenched_blade-invoke"] = "烈淬刀：你可以弃置一张牌，令你对 %dest 造成的伤害+1",
}

skill:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash" and not player:isNude() and
      player.room.logic:damageByCardEffect() and player:usedSkillTimes(skill.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, id in ipairs(player:getCardIds("he")) do
      if not player:prohibitDiscard(id) and
        not (table.contains(player:getEquipments(Card.SubtypeWeapon), id) and Fk:getCardById(id).name == skill.attached_equip) then
        table.insert(cards, id)
      end
    end
    cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = skill.name,
      cancelable = true,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#quenched_blade-invoke::" .. data.to.id,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {data.to}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, skill.name, player, player)
    data:changeDamage(1)
  end,
})

skill:addEffect("targetmod", {
  residue_func = function(self, player, s, scope)
    if player:hasSkill(skill.name) and s.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return 1
    end
  end,
})

return skill
