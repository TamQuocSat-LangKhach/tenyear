local fengshi = fk.CreateSkill {
  name = "ty__fengshih",
}

Fk:loadTranslationTable{
  ["ty__fengshih"] = "锋势",
  [":ty__fengshih"] = "当你使用牌指定目标后，若有目标角色的手牌数小于你，你可以弃置你与其各一张牌，然后此牌对其伤害+1；"..
  "当你成为其他角色使用牌的目标后，若你的手牌数小于其，你可以弃置你与其各一张牌，然后此牌对你伤害+1。",

  ["#ty__fengshih-invoke"] = "锋势：你可以弃置你与 %dest 各一张牌，令此牌伤害+1",
  ["#ty__fengshih-choose"] = "锋势：你可以弃置你与一名目标角色各一张牌，令此牌伤害+1",

  ["$ty__fengshih1"] = "锋芒之锐，势不可挡！",
  ["$ty__fengshih2"] = "势须砥砺，就其锋芒。",
}

fengshi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengshi.name) and data.firstTarget and
      table.find(data.use.tos, function (p)
        return not p.dead and p:getHandcardNum() < player:getHandcardNum()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.use.tos, function (p)
      return not p.dead and p:getHandcardNum() < player:getHandcardNum()
    end)
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = fengshi.name,
        prompt = "#ty__fengshih-invoke::"..targets[1].id,
      }) then
        event:setCostData(self, {tos = targets})
        return true
      end
    else
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ty__fengshih-choose",
        skill_name = fengshi.name,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = fengshi.name,
      cancelable = false,
    })
    if player.dead then return end
    if not to:isNude() and not to.dead then
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = fengshi.name,
      })
      room:throwCard(card, fengshi.name, to, player)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__fengshih = data.extra_data.ty__fengshih or {}
    table.insert(data.extra_data.ty__fengshih, to.id)
  end,
})

fengshi:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengshi.name) and
      not data.from.dead and data.from:getHandcardNum() > player:getHandcardNum()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = fengshi.name,
      prompt = "#ty__fengshih-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = fengshi.name,
      cancelable = false,
    })
    if player.dead then return end
    if not data.from:isNude() and not data.from.dead then
      local card = room:askToChooseCard(player, {
        target = data.from,
        flag = "he",
        skill_name = fengshi.name,
      })
      room:throwCard(card, fengshi.name, data.from, player)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__fengshih = data.extra_data.ty__fengshih or {}
    table.insert(data.extra_data.ty__fengshih, player.id)
  end,
})

fengshi:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event == nil then return end
      local use = use_event.data
      return use.extra_data and use.extra_data.ty__fengshih and table.contains(use.extra_data.ty__fengshih, player.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return fengshi
