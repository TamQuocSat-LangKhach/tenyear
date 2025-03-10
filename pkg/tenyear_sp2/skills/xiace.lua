local xiace = fk.CreateSkill {
  name = "xiace"
}

Fk:loadTranslationTable{
  ['xiace'] = '黠策',
  ['#xiace-recover'] = '是否发动 黠策，弃置一张牌来回复1点体力',
  ['#xiace-control'] = '是否发动 黠策，选择一名其他角色，令其本回合所有非锁定技失效',
  ['@@xiace-turn'] = '黠策',
  [':xiace'] = '每回合各限一次，当你受到伤害后，你可令一名其他角色的所有非锁定技于本回合内失效；当你造成伤害后，你可以弃置一张牌并回复1点体力。',
  ['$xiace1'] = '风之积非厚，其负大翼也无力。',
  ['$xiace2'] = '人情同于抔土，岂穷达而异心。',
}

xiace:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and player:getMark("xiace_damage-turn") == 0 and not player:isNude()
  end,
  on_cost = function(self, event, target, player)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = skill.name,
      cancelable = true,
      pattern = ".",
      prompt = "#xiace-recover",
      skip = true
    })
    if #card > 0 then
      event:setCostData(skill, card)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "xiace_damage-turn", 1)
    room:throwCard(event:getCostData(skill), skill.name, player)
    if not player.dead and player:isWounded() then
      room:recover {
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skill.name,
      }
    end
  end,
})

xiace:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and player:getMark("xiace_damaged-turn") == 0
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xiace-control",
      skill_name = skill.name,
      cancelable = true
    })
    if #targets > 0 then
      event:setCostData(skill, targets[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "xiace_damaged-turn", 1)
    local tar = room:getPlayerById(event:getCostData(skill))
    room:addPlayerMark(tar, "@@xiace-turn")
    room:addPlayerMark(tar, MarkEnum.UncompulsoryInvalidity .. "-turn")
  end,
})

return xiace
