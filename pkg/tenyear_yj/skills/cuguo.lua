local cuguo = fk.CreateSkill {
  name = "cuguo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["cuguo"] = "蹙国",
  [":cuguo"] = "锁定技，当你对一名角色使用的牌被抵消后，若你本回合未发动此技能，你须弃置一张牌，令你于此牌结算后视为对该角色"..
  "使用一张牌名相同的牌，若此牌仍被抵消，你失去1点体力。",

  ["$cuguo1"] = "本欲开疆拓土，奈何丧师辱国。",
  ["$cuguo2"] = "千里锦绣之地，皆亡逆贼之手。",
}

cuguo:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(cuguo.name) and data.from == player and
      player:usedSkillTimes(cuguo.name, Player.HistoryTurn) == 0 and
      #data.tos > 0
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
      local use = e.data
      use.extra_data = use.extra_data or {}
      use.extra_data.cuguo_to = data.to
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return data.from == player and table.contains(data.card.skillNames, cuguo.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data
      use.extra_data = use.extra_data or {}
      use.extra_data.cuguo_negative = true
    end
  end,
})

cuguo:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead then
      if (data.extra_data or {}).cuguo_to then
        return true
      elseif table.contains(data.card.skillNames, cuguo.name) then
        return (data.extra_data or {}).cuguo_negative
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if (data.extra_data or {}).cuguo_to then
      local to = data.extra_data.cuguo_to
      if not to.dead then
        room:useVirtualCard(data.card.name, nil, player, to, cuguo.name, true)
      end
    else
      room:loseHp(player, 1, cuguo.name)
    end
  end,
})

return cuguo
