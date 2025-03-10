local ty__tunjiang = fk.CreateSkill {
  name = "ty__tunjiang"
}

Fk:loadTranslationTable{
  ['ty__tunjiang'] = '屯江',
  [':ty__tunjiang'] = '结束阶段，若你于本回合出牌阶段内未使用牌指定过其他角色为目标，则你可以摸X张牌（X为全场势力数）。',
  ['$ty__tunjiang1'] = '这浑水，不蹚也罢。',
  ['$ty__tunjiang2'] = '荆州风云波澜动，唯守江夏避险峻。',
}

ty__tunjiang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(ty__tunjiang.name) and player.phase == Player.Finish then
      local play_ids = {}
      player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
        if e.data[2] == Player.Play and e.end_id then
          table.insert(play_ids, {e.id, e.end_id})
        end
        return false
      end, Player.HistoryTurn)
      if #play_ids == 0 then return true end
      local used = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local in_play = false
        for _, ids in ipairs(play_ids) do
          if e.id > ids[1] and e.id < ids[2] then
            in_play = true
            break
          end
        end
        if in_play then
          local use = e.data[1]
          if use.from == target.id and use.tos then
            if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= target.id end) then
              return true
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      return #used == 0
    end
  end,
  on_use = function(self, event, player)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player:drawCards(#kingdoms)
  end,
})

return ty__tunjiang
