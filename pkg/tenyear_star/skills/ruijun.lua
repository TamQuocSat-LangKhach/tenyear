local ruijun = fk.CreateSkill {
  name = "ruijun",
}

Fk:loadTranslationTable{
  ["ruijun"] = "锐军",
  [":ruijun"] = "当你于出牌阶段内第一次使用牌指定其他角色为目标后，你可以摸X张牌（X为你已损失的体力值+1），此阶段内：除其外的其他角色视为"..
  "不在你的攻击范围内；你对其使用牌无距离限制；当你对其造成伤害时，伤害值比上次增加1（至多为5）。",

  ["#ruijun-invoke"] = "锐军：是否对 %dest 发动“锐军”，摸牌并令你此阶段对其使用牌无距离限制、伤害增加",
  ["#ruijun-choose"] = "锐军：是否选择一名目标发动“锐军”，摸牌并令你此阶段对其使用牌无距离限制、伤害增加",
  ["@@ruijun-phase"] = "锐军",

  ["$ruijun1"] = "三军夺锐，势不可挡。",
  ["$ruijun2"] = "士如钢锋，可破三属之甲。",
}

ruijun:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ruijun.name) and player.phase == Player.Play and data.firstTarget and
      player:getMark("ruijun_record-phase") == 0 then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == player and
          table.find(use.tos, function (p)
            return p ~= player
          end) then
          room:setPlayerMark(player, "ruijun_record-phase", e.id)
          return true
        end
      end, Player.HistoryPhase)
      return use_event.id == player:getMark("ruijun_record-phase")
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.use.tos, function (p)
      return p ~= player and not p.dead
    end)
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = ruijun.name,
        prompt = "#ruijun-invoke::"..targets[1].id,
      }) then
        event:setCostData(self, {tos = targets})
        return true
      end
    else
      targets = room:askToChoosePlayers(player, {
        skill_name = ruijun.name,
        min_num = 1,
        max_num = 1,
        targets = targets,
        prompt = "#ruijun-choose",
      })
      if #targets > 0 then
        event:setCostData(self, {tos = targets})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    player:drawCards(player:getLostHp() + 1, ruijun.name)
    if player.dead or to.dead then return end
    room:setPlayerMark(to, "@@ruijun-phase", 1)
    room:setPlayerMark(player, "ruijun_targets-phase", to.id)
  end,
})

ruijun:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("ruijun_targets-phase") == data.to.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
    if phase_event == nil then return end
    local x = 0
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data
      if damage.from == player and damage.to == data.to then
        x = damage.damage
        return true
      end
    end, nil, phase_event.id)
    x = math.min(5, x + 1) - data.damage
    if x ~= 0 then
      data:changeDamage(x)
    end
  end,
})

ruijun:addEffect("atkrange", {
  without_func = function (self, from, to)
    local mark = from:getMark("ruijun_targets-phase")
    return mark ~= 0 and mark ~= to.id
  end,
})

ruijun:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and player:getMark("ruijun_targets-phase") == to.id
  end,
})

return ruijun
