local xieju = fk.CreateSkill{
  name = "ty__xieju",
}

Fk:loadTranslationTable{
  ["ty__xieju"] = "偕举",
  [":ty__xieju"] = "出牌阶段限一次，你可以选择令任意名本回合成为过牌的目标的角色，这些角色依次视为使用一张【杀】。",

  ["#ty__xieju"] = "偕举：选择任意名角色，这些角色视为使用一张【杀】",
  ["#ty__xieju-slash"] = "偕举：请视为使用【杀】",

  ["$ty__xieju1"] = "你我本为袍泽，戎行何分先后。",
  ["$ty__xieju2"] = "义不吝众，举义旗者皆老夫兄弟。",
}

xieju:addAcquireEffect(function (self, player, is_start)
  if player.room.current == player then
    local room = player.room
    local mark = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      for _, p in ipairs(use.tos) do
        table.insertIfNeed(mark, p.id)
      end
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "ty__xieju-turn", mark)
  end
end)

xieju:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty__xieju",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xieju.name, Player.HistoryPhase) == 0 and player:getMark("ty__xieju-turn") ~= 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return table.contains(player:getTableMark("ty__xieju-turn"), to_select.id) and
      to_select:canUse(Fk:cloneCard("slash"), {bypass_times = true})
  end,
  on_use = function(self, room, effect)
    room:sortByAction(effect.tos)
    for _, target in ipairs(effect.tos) do
      if not target.dead then
        room:askToUseVirtualCard(target, {
          name = "slash",
          skill_name = xieju.name,
          prompt = "#ty__xieju-slash",
          cancelable = false,
          extra_data = {
            bypass_times = true,
            extraUse = true,
          },
        })
      end
    end
  end,
})
xieju:addEffect(fk.TargetConfirmed, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(xieju.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, "ty__xieju-turn", target.id)
  end,
})

return xieju
