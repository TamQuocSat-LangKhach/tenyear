local lianzhan = fk.CreateSkill {
  name = "lianzhan",
}

Fk:loadTranslationTable{
  ["lianzhan"] = "连战",
  [":lianzhan"] = "当你使用伤害牌指定唯一目标时，你可以选择一项：1.额外指定一个目标；2.此牌额外结算一次。然后若此牌对目标造成伤害次数为2，"..
  "你可以回复1点体力（若你未受伤改为摸两张牌）；为0，目标角色视为对你使用同名牌。",

  ["#lianzhan-choose"] = "连战：你可以令此%arg额外指定目标或额外结算一次",
  ["#lianzhan-recover"] = "连战：是否回复1点体力？",
  ["#lianzhan-draw"] = "连战：是否摸两张牌？",

  ["$lianzhan1"] = "",
  ["$lianzhan2"] = "",
}

lianzhan:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianzhan.name) and 
      data:isOnlyTarget(data.tos[1]) and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "lianzhan_active",
      prompt = "#lianzhan-choose:::"..data.card:toLogString(),
      extra_data = {
        exclusive_targets = table.map(data:getExtraTargets(), Util.IdMapper),
      }
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local choice = event:getCostData(self).choice
    if choice == "lianzhan_target" then
      data:addTarget(event:getCostData(self).tos[1])
    else
      data.additionalEffect = (data.additionalEffect or 0) + 1
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.lianzhan = player
  end,
})

lianzhan:addEffect(fk.Damaged, {
  can_refresh = function (self, event, target, player, data)
    if target == player and data.card then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data
        if use.extra_data and use.extra_data.lianzhan then
          return table.contains(use.tos, player)
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event then
      local use = use_event.data
      use.extra_data = use.extra_data or {}
      use.extra_data.lianzhan_count = (use.extra_data.lianzhan_count or 0) + 1
    end
  end,
})

lianzhan:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and data.extra_data and data.extra_data.lianzhan == player and
      (data.extra_data.lianzhan_count == 2 or data.extra_data.lianzhan_count == 0 or data.extra_data.lianzhan_count == nil)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = data.extra_data.lianzhan_count
    if n == nil or n == 0 then
      event:setCostData(self, {choice = "negative"})
      return true
    elseif n == 2 then
      if player:isWounded() then
        if room:askToSkillInvoke(player, {
          skill_name = "lianzhan",
          prompt = "#lianzhan-recover"
        }) then
          event:setCostData(self, {choice = "recover"})
          return true
        end
      elseif room:askToSkillInvoke(player, {
        skill_name = "lianzhan",
        prompt = "#lianzhan-draw"
      }) then
        event:setCostData(self, {choice = "draw"})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    player:broadcastSkillInvoke(lianzhan.name)
    if choice == "recover" then
      if player:isWounded() then
        room:notifySkillInvoked(player, lianzhan.name, "support")
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = lianzhan.name,
        }
      end
    elseif choice == "draw" then
      room:notifySkillInvoked(player, lianzhan.name, "drawcard")
      player:drawCards(2, lianzhan.name)
    elseif choice == "negative" then
      room:notifySkillInvoked(player, lianzhan.name, "negative")
      room:sortByAction(data.tos)
      for _, p in ipairs(data.tos) do
        if player.dead then return end
        if not p.dead then
          room:useVirtualCard(data.card.name, nil, p, player, lianzhan.name, true)
        end
      end
    end
  end,
})

return lianzhan
