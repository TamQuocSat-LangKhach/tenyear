local zhengqing = fk.CreateSkill {
  name = "zhengqing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhengqing"] = "争擎",
  [":zhengqing"] = "锁定技，每轮结束时，移去所有“擎”标记，然后本轮单回合内造成伤害值最多的角色获得X个“擎”标记并与你各摸一张牌"..
  "（X为其该回合造成的伤害数）。若是你获得“擎”且是获得数量最多的一次，你改为摸X张牌（最多摸5）。",

  ["@zhengqing_qing"] = "擎",

  ["$zhengqing1"] = "锐势夺志，斩将者虎候是也！",
  ["$zhengqing2"] = "三军争勇，擎纛者舍我其谁！",
}

zhengqing:addEffect(fk.RoundEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhengqing.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.players) do
      if p:getMark("@zhengqing_qing") then
        room:setPlayerMark(p, "@zhengqing_qing", 0)
      end
    end

    local turn_events = room.logic:getEventsOfScope(GameEvent.Turn, 999, Util.TrueFunc, Player.HistoryRound)
    local damage_events = room.logic:getActualDamageEvents(999, Util.TrueFunc, Player.HistoryRound)

    if #turn_events > 0 and #damage_events > 0 then
      local index = 1
      local bestRecord = {}
      for i = 1, #turn_events do
        local records = {}
        for j = index, #damage_events do
          index = j
          local phase_event = turn_events[i]
          local damage_event = damage_events[j]
          if phase_event.id < damage_event.id and (i == #turn_events or turn_events[i + 1].id > damage_event.id) then
            local damage = damage_event.data
            if damage.from then
              records[damage.from] = (records[damage.from] or 0) + damage.damage
            end
          end
          if i < #turn_events and turn_events[i + 1].id < damage_event.id then
            break
          end
        end

        for p, damage in pairs(records) do
          local n = bestRecord.damage or 0
          if damage > n then
            bestRecord = { players = { p }, damage = damage }
          elseif damage == n then
            table.insertIfNeed(bestRecord.players, p)
          end
        end
      end

      local winner = table.find(bestRecord.players, function(p)
        return p == player
      end) or table.random(bestRecord.players)
      if winner and not winner.dead then
        local preRecord = (room:getBanner("zhengqing_best") or 0)
        room:addPlayerMark(winner, "@zhengqing_qing", bestRecord.damage)
        room:setBanner("zhengqing_best", bestRecord.damage)
        if winner == player and bestRecord.damage > preRecord then
          player:drawCards(math.min(bestRecord.damage, 5), zhengqing.name)
        else
          local players = { winner, player }
          room:sortByAction(players)
          for _, p in ipairs(players) do
            if not p.dead then
              p:drawCards(1, zhengqing.name)
            end
          end
        end
      end
    end
  end,
})

return zhengqing
