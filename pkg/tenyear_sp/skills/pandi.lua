local pandi = fk.CreateSkill {
  name = "pandi",
}

Fk:loadTranslationTable{
  ["pandi"] = "盻睇",
  [":pandi"] = "出牌阶段，你可以选择一名本回合未造成过伤害的其他角色，你此阶段内使用的下一张牌改为由其对你选择的目标使用。<br/>"..
  "<font color=>（村：发动后必须立即使用牌，且不支持转化使用，否则必须使用一张牌之后才能再次发动此技能）</font>",

  ["#pandi"] = "盻睇：选择一名其他角色，你的下一张牌视为由该角色使用",
  ["#pandi-use"] = "盻睇：选择一张牌并选择目标，视为由 %dest 使用",

  ["$pandi1"] = "待君归时，共泛轻舟于湖海。",
  ["$pandi2"] = "妾有一曲，可壮卿之峥嵘。",
}

pandi:addEffect("active", {
  anim_type = "control",
  prompt = "#pandi",
  can_use = function(self, player)
    return player:getMark("pandi_prohibit-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:getMark("pandi_damaged-turn") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:setPlayerMark(player, "pandi_prohibit-phase", 1)
    room:setPlayerMark(player, "pandi_target", target.id)
    local general_info = {player.general, player.deputyGeneral}
    player.general = target.general
    player.deputyGeneral = target.deputyGeneral
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "deputyGeneral")
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "pandi_active",
      prompt = "#pandi-use::"..target.id,
      cancelable = true,
      extra_data = {
        pandi = target.id,
      }
    })
    room:setPlayerMark(player, "pandi_target", 0)
    player.general = general_info[1]
    player.deputyGeneral = general_info[2]
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "deputyGeneral")
    if success and dat then
      room:useCard({
        from = target,
        tos = dat.targets,
        card = Fk:getCardById(dat.cards[1]),
      })
    end
  end,
})

pandi:addAcquireEffect(function (self, player, is_start)
  if not is_start and player.room.current == player then
    local room = player.room
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data
      if damage.from and not damage.from.dead then
        room:setPlayerMark(damage.from, "pandi_damaged-turn", 1)
      end
    end, Player.HistoryTurn)
  end
end)
pandi:addEffect(fk.Damage, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("pandi_damaged-turn") == 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "pandi_damaged-turn", 1)
  end,
})

pandi:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("pandi_prohibit-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "pandi_prohibit-phase", 0)
  end,
})

return pandi
