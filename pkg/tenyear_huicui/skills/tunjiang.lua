local tunjiang = fk.CreateSkill{
  name = "ty__tunjiang",
}

Fk:loadTranslationTable{
  ["ty__tunjiang"] = "屯江",
  [":ty__tunjiang"] = "结束阶段，若你本回合出牌阶段内未使用牌指定过其他角色为目标，你可以摸X张牌（X为全场势力数）。",

  ["$ty__tunjiang1"] = "这浑水，不蹚也罢。",
  ["$ty__tunjiang2"] = "荆州风云波澜动，唯守江夏避险峻。",
}

tunjiang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tunjiang.name) and player.phase == Player.Finish then
      local phase_events = player.room.logic:getEventsOfScope(GameEvent.Phase, 999, function (e)
        return e.data.phase == Player.Play
      end, Player.HistoryTurn)
      return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from and table.find(use.tos, function (p)
          return p ~= player
        end) and
        table.find(phase_events, function (phase)
          return phase.id < e.id and phase.end_id > e.id
        end) ~= nil
      end, Player.HistoryTurn) == 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player:drawCards(#kingdoms, tunjiang.name)
  end,
})

return tunjiang
