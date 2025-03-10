local ty_ex__zishou = fk.CreateSkill {
  name = "ty_ex__zishou"
}

Fk:loadTranslationTable{
  ['ty_ex__zishou'] = '自守',
  ['#ty_ex__zishou-draw'] = '自守：你可以多摸 %arg 张牌，防止本回合你对其他角色造成的伤害',
  ['ty_ex__zishou_active'] = '自守',
  ['#ty_ex__zishou-discard'] = '自守：可以弃置任意张花色各不相同的手牌，摸等量的牌',
  ['@@ty_ex__zishou-turn'] = '自守',
  [':ty_ex__zishou'] = '①摸牌阶段，你可以多摸X张牌（X为全场势力数），然后本回合你对其他角色造成伤害时，防止之；<br>②结束阶段，若你本回合没有对其他角色使用过牌，你可以弃置任意张花色各不相同的手牌，摸等量的牌。',
  ['$ty_ex__zishou1'] = '恩威并著，从容自保！',
  ['$ty_ex__zishou2'] = '据有荆州，以观世事！',
}

-- Effect for DrawNCards and EventPhaseStart
ty_ex__zishou:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty_ex__zishou.name)
  end,
  on_cost = function (skill, event, target, player)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    local num = #kingdoms
    if room:askToSkillInvoke(player, { skill_name = ty_ex__zishou.name, prompt = "#ty_ex__zishou-draw:::"..num }) then
      event:setCostData(skill, num)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    data.n = data.n + event:getCostData(skill)
    room:setPlayerMark(player, "@@ty_ex__zishou-turn", 1)
  end,
})

ty_ex__zishou:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty_ex__zishou.name) and player.phase == Player.Finish and not player:isKongcheng() and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        if use.from == player.id and use.tos then
          if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= player.id end) then
            return true
          end
        end
        return false
      end, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (skill, event, target, player)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__zishou_active",
      prompt = "#ty_ex__zishou-discard",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(skill, dat.cards)
      return true
    end
  end,
})

-- Effect for DamageCaused
ty_ex__zishou:addEffect(fk.DamageCaused, {
  name = "#ty_ex__zishou_delay",
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and data.to ~= player and player:getMark("@@ty_ex__zishou-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (skill, event, target, player)
    player:broadcastSkillInvoke("ty_ex__zishou")
    return true
  end,
})

return ty_ex__zishou
