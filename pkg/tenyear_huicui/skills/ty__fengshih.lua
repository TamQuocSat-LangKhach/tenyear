local ty__fengshih = fk.CreateSkill {
  name = "ty__fengshih"
}

Fk:loadTranslationTable{
  ['ty__fengshih'] = '锋势',
  ['#ty__fengshih-invoke'] = '是否对 %dest 发动 锋势，弃置你与其各一张牌',
  ['#ty__fengshih-choose'] = '是否发动 锋势，弃置你与一名目标角色的各一张牌',
  ['#ty__fengshih_delay'] = '锋势',
  [':ty__fengshih'] = '当你使用牌指定第一个目标后，若其中一名目标角色手牌数小于你，你可以弃置你与其各一张牌，然后此牌对其伤害+1；当你成为其他角色使用牌的目标后，若你的手牌数小于其，你可以弃置你与其各一张牌，然后此牌对你伤害+1。',
  ['$ty__fengshih1'] = '锋芒之锐，势不可挡！',
  ['$ty__fengshih2'] = '势须砥砺，就其锋芒。',
}

-- ty__fengshih
ty__fengshih:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty__fengshih.name) then
      if not data.firstTarget then return false end
      local room = player.room
      local n = player:getHandcardNum()
      local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
        local to = room:getPlayerById(id)
        return not to.dead and to:getHandcardNum() < n
      end)
      if #targets > 0 then
        event:setCostData(self, targets)
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(event:getCostData(self))
    if #targets == 1 then
      if room:askToSkillInvoke(player, {skill_name = ty__fengshih.name, prompt = "#ty__fengshih-invoke::" .. targets[1]}) then
        room:doIndicate(player.id, targets)
        event:setCostData(self, targets)
        return true
      end
    else
      local chosen_targets = room:askToChoosePlayers(player, {targets = targets, min_num = 1, max_num = 1, prompt = "#ty__fengshih-choose", skill_name = ty__fengshih.name, cancelable = true})
      if #chosen_targets > 0 then
        event:setCostData(self, chosen_targets)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self)[1])
    room:askToDiscard(player, {min_num = 1, max_num = 1, include_equip = true, skill_name = ty__fengshih.name, cancelable = false})
    if player.dead then return false end
    if not to:isNude() then
      local card = room:askToChooseCard(player, {target = to, flag = "he", skill_name = ty__fengshih.name})
      room:throwCard({card}, ty__fengshih.name, to, player)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__fengshih = data.extra_data.ty__fengshih or {}
    table.insert(data.extra_data.ty__fengshih, to.id)
  end,
})

ty__fengshih:addEffect(fk.TargetConfirmed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty__fengshih.name) then
      local room = player.room
      local from = room:getPlayerById(data.from)
      if not from.dead and from:getHandcardNum() > player:getHandcardNum() then
        event:setCostData(self, {data.from})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self)[1])
    room:askToDiscard(player, {min_num = 1, max_num = 1, include_equip = true, skill_name = ty__fengshih.name, cancelable = false})
    if player.dead then return false end
    if not to:isNude() then
      local card = room:askToChooseCard(player, {target = to, flag = "he", skill_name = ty__fengshih.name})
      room:throwCard({card}, ty__fengshih.name, to, player)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__fengshih = data.extra_data.ty__fengshih or {}
    table.insert(data.extra_data.ty__fengshih, player.id)
  end,
})

-- ty__fengshih_delay
ty__fengshih:addEffect(fk.DamageInflicted, {
  name = "#ty__fengshih_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or target ~= player then return false end
    local room = player.room
    local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not card_event then return false end
    local use = card_event.data[1]
    return use.extra_data and use.extra_data.ty__fengshih and table.contains(use.extra_data.ty__fengshih, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

return ty__fengshih
