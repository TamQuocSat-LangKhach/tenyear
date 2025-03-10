local waterSwordSkill = fk.CreateSkill {
  name = "#water_sword_skill"
}

Fk:loadTranslationTable{
  ['#water_sword_skill'] = '水波剑',
  ['water_sword'] = '水波剑',
  ['#water_sword-invoke'] = '水波剑：你可以为%arg额外指定一个目标',
}

waterSwordSkill:addEffect(fk.AfterCardTargetDeclared, {
  attached_equip = "water_sword",
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(waterSwordSkill) and player:getMark("water_sword_usedtimes-turn") < 2 and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and #player.room:getUseExtraTargets(data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getUseExtraTargets(data),
      min_num = 1,
      max_num = 1,
      prompt = "#water_sword-invoke:::" .. data.card:toLogString(),
      skill_name = waterSwordSkill.name,
      cancelable = true
    })
    if #to > 0 then
      room:addPlayerMark(player, "water_sword_usedtimes-turn")
      event:setCostData(skill, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    table.insert(data.tos, event:getCostData(skill).tos)
  end,
})

waterSwordSkill:addEffect(fk.AfterCardsMove, {
  attached_equip = "water_sword",
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player.dead or not player:isWounded() then return false end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).name == skill.attached_equip then
            return skill:isEffectable(player)
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(skill, {})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = waterSwordSkill.name
    })
  end,
})

return waterSwordSkill
