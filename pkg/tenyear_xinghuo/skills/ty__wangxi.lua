local ty__wangxi = fk.CreateSkill {
  name = "ty__wangxi"
}

Fk:loadTranslationTable{
  ['ty__wangxi'] = '忘隙',
  ['#ty__wangxi-invoke'] = '是否对 %dest 发动 忘隙',
  ['#ty__wangxi-give'] = '忘隙：选择一张牌，交给 %dest',
  [':ty__wangxi'] = '当你对其他角色造成1点伤害后，或当你受到其他角色造成的1点伤害后，若其存活，你可以摸两张牌，然后将一张牌交给该角色。',
  ['$ty__wangxi1'] = '小隙沉舟，同心方可戮力。',
  ['$ty__wangxi2'] = '为天下苍生，自当化解私怨。',
}

ty__wangxi:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__wangxi.name) and data.from and data.from ~= data.to and not (data.from.dead or data.to.dead)
  end,
  on_trigger = function(self, event, target, player, data)
    skill.cancel_cost = false
    for i = 1, data.damage do
      if skill.cancel_cost then break end
      if not skill:triggerable(event, target, player, data) then break end
      skill:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = event == fk.Damage and data.to or data.from
    if player.room:askToSkillInvoke(player, {skill_name = ty__wangxi.name, prompt = "#ty__wangxi-invoke::"..to.id}) then
      player.room:doIndicate(player.id, {to.id})
      return true
    end
    skill.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty__wangxi.name)
    room:notifySkillInvoked(player, ty__wangxi.name, event == fk.Damaged and "masochism" or "drawcard")
    room:drawCards(player, 2, ty__wangxi.name)
    local to = event == fk.Damage and data.to or data.from
    if player.dead or player:isNude() or to.dead then return false end
    local card = room:askToCards(player, {min_num = 1, max_num = 1, include_equip = true, skill_name = ty__wangxi.name, prompt = "#ty__wangxi-give::"..to.id})
    if #card > 0 then
      room:moveCardTo(card[1], Card.PlayerHand, to, fk.ReasonGive, ty__wangxi.name, nil, false, player.id)
    end
  end,
})

ty__wangxi:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__wangxi.name) and data.from and data.from ~= data.to and not (data.from.dead or data.to.dead)
  end,
  on_trigger = function(self, event, target, player, data)
    skill.cancel_cost = false
    for i = 1, data.damage do
      if skill.cancel_cost then break end
      if not skill:triggerable(event, target, player, data) then break end
      skill:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = event == fk.Damage and data.to or data.from
    if player.room:askToSkillInvoke(player, {skill_name = ty__wangxi.name, prompt = "#ty__wangxi-invoke::"..to.id}) then
      player.room:doIndicate(player.id, {to.id})
      return true
    end
    skill.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty__wangxi.name)
    room:notifySkillInvoked(player, ty__wangxi.name, event == fk.Damaged and "masochism" or "drawcard")
    room:drawCards(player, 2, ty__wangxi.name)
    local to = event == fk.Damage and data.to or data.from
    if player.dead or player:isNude() or to.dead then return false end
    local card = room:askToCards(player, {min_num = 1, max_num = 1, include_equip = true, skill_name = ty__wangxi.name, prompt = "#ty__wangxi-give::"..to.id})
    if #card > 0 then
      room:moveCardTo(card[1], Card.PlayerHand, to, fk.ReasonGive, ty__wangxi.name, nil, false, player.id)
    end
  end,
})

return ty__wangxi
