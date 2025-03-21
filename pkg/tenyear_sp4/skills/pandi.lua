local pandi = fk.CreateSkill {
  name = "pandi"
}

Fk:loadTranslationTable{
  ['pandi'] = '盻睇',
  ['#pandi-active'] = '发动盻睇，选择一名其他角色，下一张牌视为由该角色使用',
  ['pandi_use'] = '盻睇',
  ['#pandi-use'] = '盻睇：选择一张牌，视为由 %dest 使用（若需要选目标则你来选择目标）',
  [':pandi'] = '出牌阶段，你可以选择一名本回合未造成过伤害的其他角色，你此阶段内使用的下一张牌改为由其对你选择的目标使用。<br /><font color=>（村：发动后必须立即使用牌，且不支持转化使用，否则必须使用一张牌之后才能再次发动此技能）</font>',
  ['$pandi1'] = '待君归时，共泛轻舟于湖海。',
  ['$pandi2'] = '妾有一曲，可壮卿之峥嵘。',
}

-- Active Skill Effect
pandi:addEffect('active', {
  anim_type = "control",
  prompt = "#pandi-active",
  can_use = function(self, player)
    return player:getMark("pandi_prohibit-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select):getMark("pandi_damaged-turn") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = effect.tos[1]
    room:setPlayerMark(player, "pandi_prohibit-phase", 1)
    room:setPlayerMark(player, "pandi_target", target)
    local general_info = {player.general, player.deputyGeneral}
    local tar_player = room:getPlayerById(target)
    player.general = tar_player.general
    player.deputyGeneral = tar_player.deputyGeneral
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "deputyGeneral")
    local _, ret = room:askToUseActiveSkill(player, {
      skill_name = "pandi_use",
      prompt = "#pandi-use::" .. target,
      cancelable = true,
    })
    room:setPlayerMark(player, "pandi_target", 0)
    player.general = general_info[1]
    player.deputyGeneral = general_info[2]
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "deputyGeneral")
    if ret then
      room:useCard({
        from = target,
        tos = table.map(ret.targets, function(pid) return { pid } end),
        card = Fk:getCardById(ret.cards[1]),
      })
    end
  end,
})

-- Trigger Skill Effect for Refresh Events
pandi:addEffect(fk.EventAcquireSkill | fk.Damage | fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      return player == target and player:getMark("pandi_damaged-turn") == 0
    elseif event == fk.EventAcquireSkill then
      return player == target and player.room.current == player and player.room:getBanner("RoundCount")
    elseif event == fk.PreCardUse then
      return player:getMark("pandi_prohibit-phase") > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "pandi_damaged-turn")
    elseif event == fk.EventAcquireSkill then
      local room = player.room
      local current_event = room.logic:getCurrentEvent()
      if not current_event then return false end
      local start_event = current_event:findParent(GameEvent.Turn, true)
      if not start_event then return false end
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local damage = e.data[5]
        if damage and damage.from then
          room:addPlayerMark(damage.from, "pandi_damaged-turn")
        end
      end, Player.HistoryTurn)
    elseif event == fk.PreCardUse then
      player.room:setPlayerMark(player, "pandi_prohibit-phase", 0)
    end
  end,
})

return pandi
