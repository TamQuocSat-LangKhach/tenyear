local wencan = fk.CreateSkill {
  name = "wencan"
}

Fk:loadTranslationTable{
  ['wencan'] = '文灿',
  ['#wencan'] = '文灿：选择至多两名体力值不同的角色，其弃牌或你对其使用牌无限制',
  ['wencan_active'] = '文灿',
  ['#wencan-discard'] = '文灿：弃置两张不同花色的牌，否则 %src 本回合对你使用牌无限制',
  ['@@wencan-turn'] = '文灿',
  [':wencan'] = '出牌阶段限一次，你可以选择至多两名体力值不同的角色，这些角色依次选择一项：1.弃置两张花色不同的牌；2.本回合你对其使用牌无距离和次数限制。',
  ['$wencan1'] = '宴友以文，书声喧哗，众宾欢也。',
  ['$wencan2'] = '众星灿于九天，犹雅文耀于万世。',
}

-- 主动技部分
wencan:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  prompt = "#wencan",
  can_use = function(self, player)
    return player:usedSkillTimes(wencan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected > 1 or to_select == player.id then return false end
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:currentRoom():getPlayerById(to_select).hp ~= Fk:currentRoom():getPlayerById(selected[1]).hp
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if not room:askToUseActiveSkill(p, {
          skill_name = "wencan_active",
          prompt = "#wencan-discard:"..player.id,
          cancelable = true,
        }) then
          room:setPlayerMark(p, "@@wencan-turn", 1)
        end
      end
    end
  end,
})

-- 刷新技能部分
wencan:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    if player == target and player:usedSkillTimes(wencan.name, Player.HistoryTurn) > 0 then
      return table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return player.room:getPlayerById(pid):getMark("@@wencan-turn") > 0
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

-- 目标修正技能部分
wencan:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:usedSkillTimes(wencan.name, Player.HistoryTurn) > 0 and scope == Player.HistoryPhase and
      to and to:getMark("@@wencan-turn") > 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:usedSkillTimes(wencan.name, Player.HistoryTurn) > 0 and to and to:getMark("@@wencan-turn") > 0
  end,
})

return wencan
