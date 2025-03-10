local cuguo = fk.CreateSkill {
  name = "cuguo"
}

Fk:loadTranslationTable{
  ['cuguo'] = '蹙国',
  [':cuguo'] = '锁定技，当你对一名角色使用的牌被抵消后，若你本回合未发动此技能，你须弃置一张牌，令你于此牌结算后视为对该角色使用一张牌名相同的牌，若此牌仍被抵消，你失去1点体力。',
  ['$cuguo1'] = '本欲开疆拓土，奈何丧师辱国。',
  ['$cuguo2'] = '千里锦绣之地，皆亡逆贼之手。',
}

-- 主技能效果
cuguo:addEffect(fk.CardEffectCancelledOut, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(cuguo) and data.from and data.from == player.id and player:usedSkillTimes(cuguo.name, Player.HistoryTurn) == 0
      and #TargetGroup:getRealTargets(data.tos) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = cuguo.name,
      cancelable = false,
    })
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      use.extra_data = use.extra_data or {}
      use.extra_data.cuguo_to = data.to
    end
  end,
})

-- 触发技能效果
cuguo:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if data.from and data.from == player.id and not player.dead then
      if (data.extra_data or {}).cuguo_to then
        return true
      elseif table.contains(data.card.skillNames, "cuguo") then
        return (data.extra_data or {}).cuguo_negative
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if (data.extra_data or {}).cuguo_to then
      local to = room:getPlayerById(data.extra_data.cuguo_to)
      if not to.dead then
        room:useVirtualCard(data.card.name, nil, player, to, "cuguo", true)
      end
    else
      room:loseHp(player, 1, "cuguo")
    end
  end,
})

-- 刷新效果
cuguo:addEffect(fk.CardEffectCancelledOut, {
  can_refresh = function(self, event, target, player, data)
    return data.from == player.id and table.contains(data.card.skillNames, "cuguo")
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      use.extra_data = use.extra_data or {}
      use.extra_data.cuguo_negative = true
    end
  end,
})

return cuguo
