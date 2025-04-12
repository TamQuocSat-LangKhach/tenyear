local zishou = fk.CreateSkill {
  name = "ty_ex__zishou",
}

Fk:loadTranslationTable{
  ["ty_ex__zishou"] = "自守",
  [":ty_ex__zishou"] = "摸牌阶段，你可以多摸X张牌（X为全场势力数），然后本回合你对其他角色造成伤害时，防止此伤害。结束阶段，"..
  "若你本回合没有使用牌指定其他角色为目标，你可以弃置任意张花色各不相同的手牌，摸等量的牌。",

  ["#ty_ex__zishou-draw"] = "自守：你可以多摸%arg张牌，防止本回合你对其他角色造成的伤害",
  ["#ty_ex__zishou-discard"] = "自守：你可以弃置任意张花色各不相同的手牌，摸等量的牌",

  ["$ty_ex__zishou1"] = "恩威并著，从容自保！",
  ["$ty_ex__zishou2"] = "据有荆州，以观世事！",
}

zishou:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zishou.name) and player.phase == Player.Draw
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    local num = #kingdoms
    if room:askToSkillInvoke(player, {
      skill_name = zishou.name,
      prompt = "#ty_ex__zishou-draw:::"..num,
    }) then
      event:setCostData(self, {choice = num})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + event:getCostData(self).choice
  end,
})

zishou:addEffect(fk.DamageCaused, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(zishou.name, Player.HistoryTurn) > 0 and data.to ~= player
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
  end,
})

zishou:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zishou.name) and player.phase == Player.Finish and
      not player:isKongcheng() and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        if use.from == player and
          table.find(use.tos, function(p)
            return p ~= player
          end) then
          return true
        end
      end, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__zishou_active",
      prompt = "#ty_ex__zishou-discard",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    room:throwCard(cards, zishou.name, player, player)
    if not player.dead then
      player:drawCards(#cards, zishou.name)
    end
  end,
})

return zishou
