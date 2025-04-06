local wencan = fk.CreateSkill {
  name = "wencan",
}

Fk:loadTranslationTable{
  ["wencan"] = "文灿",
  [":wencan"] = "出牌阶段限一次，你可以选择至多两名体力值不同的角色，这些角色依次选择一项：1.弃置两张花色不同的牌；"..
  "2.本回合你对其使用牌无距离和次数限制。",

  ["#wencan"] = "文灿：选择至多两名体力值不同的角色，其选择弃牌或你对其使用牌无距离次数限制",
  ["wencan_active"] = "文灿",
  ["#wencan-discard"] = "文灿：弃置两张不同花色的牌，否则 %src 本回合对你使用牌无限制",
  ["@@wencan-turn"] = "文灿",

  ["$wencan1"] = "宴友以文，书声喧哗，众宾欢也。",
  ["$wencan2"] = "众星灿于九天，犹雅文耀于万世。",
}

wencan:addEffect("active", {
  anim_type = "control",
  prompt = "#wencan",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(wencan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected < 2 and to_select ~= player then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return to_select.hp ~= selected[1].hp
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    for _, p in ipairs(effect.tos) do
      if not p.dead then
        local success, dat = room:askToUseActiveSkill(p, {
          skill_name = "wencan_active",
          prompt = "#wencan-discard:"..player.id,
          cancelable = true,
          skip = true,
        })
        if success and dat then
          room:throwCard(dat.cards, wencan.name, p, p)
        else
          room:setPlayerMark(p, "@@wencan-turn", 1)
          room:addTableMark(player, "wencan-turn", p.id)
        end
      end
    end
  end,
})

wencan:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return player == target and
      table.find(data.tos, function (p)
        return table.contains(player:getTableMark("wencan-turn"), p.id)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

wencan:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("wencan-turn"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and to and table.contains(player:getTableMark("wencan-turn"), to.id)
  end,
})

return wencan
