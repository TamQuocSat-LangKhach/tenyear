local ruijun = fk.CreateSkill {
  name = "ruijun"
}

Fk:loadTranslationTable{
  ['ruijun'] = '锐军',
  ['#ruijun-invoke'] = '是否对%dest发动 锐军',
  ['#ruijun-choose'] = '是否发动 锐军，选择一名角色作为目标',
  ['@@ruijun-phase'] = '锐军',
  ['#ruijun_delay'] = '锐军',
  [':ruijun'] = '当你于出牌阶段内第一次使用牌指定其他角色为目标后，你可以摸X张牌（X为你已损失的体力值+1），此阶段内：除其外的其他角色视为不在你的攻击范围内；你对其使用牌无距离限制；当你对其造成伤害时，伤害值比上次增加1（至多为5）。',
  ['$ruijun1'] = '三军夺锐，势不可挡。',
  ['$ruijun2'] = '士如钢锋，可破三属之甲。',
}

-- 主技能
ruijun:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play and player:hasSkill(ruijun.name) and data.firstTarget then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local mark = player:getMark("ruijun_record-phase")
      if mark == 0 then
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if use.from == player.id and table.find(TargetGroup:getRealTargets(use.tos), function (pid)
            return pid ~= player.id
          end) then
            mark = e.id
            room:setPlayerMark(player, "ruijun_record-phase", mark)
            return true
          end
        end, Player.HistoryPhase)
      end
      return mark == use_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
      return not room:getPlayerById(id).dead and id ~= player.id
    end)
    if #targets == 1 then
      if room:askToSkillInvoke(player, { skill_name = ruijun.name, prompt = "#ruijun-invoke::" .. targets[1] }) then
        room:doIndicate(player.id, targets)
        event:setCostData(self, targets)
        return true
      end
    else
      targets = room:askToChoosePlayers(player, { targets = targets, min_num = 1, max_num = 1, prompt = "#ruijun-choose", skill_name = ruijun.name })
      if #targets > 0 then
        event:setCostData(self, targets)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self)[1])
    player:drawCards(player:getLostHp() + 1, ruijun.name)
    if player.dead or to.dead then return false end
    room:setPlayerMark(to, "@@ruijun-phase", 1)
    room:setPlayerMark(player, "ruijun_targets-phase", to.id)
    room:setPlayerMark(player, "ruijun_event_id-phase", room.logic.current_event_id)
  end,
})

-- 延迟技能
ruijun:addEffect(fk.DamageCaused, {
  name = "#ruijun_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player:getMark("ruijun_targets-phase") == data.to.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ruijun.name)
    room:notifySkillInvoked(player, ruijun.name, "offensive")
    local x = 0
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data[1]
      if damage.from == player and damage.to == data.to then
        x = damage.damage
        return true
      end
    end, nil, player:getMark("ruijun_event_id-phase"))
    if x > 0 then
      data.damage = math.min(5, x+1)
    end
  end,
})

-- 攻击范围技能
ruijun:addEffect('atkrange', {
  name = "#ruijun_attackrange",
  without_func = function (self, from, to)
    local mark = from:getMark("ruijun_targets-phase")
    return mark ~= 0 and mark ~= to.id
  end,
})

-- 目标修正技能
ruijun:addEffect('targetmod', {
  name = "#ruijun_targetmod",
  bypass_distances = function(self, player, skill, card, to)
    return card and player:getMark("ruijun_targets-phase") == to.id
  end,
})

return ruijun
