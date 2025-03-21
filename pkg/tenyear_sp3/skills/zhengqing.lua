local zhengqing = fk.CreateSkill {
  name = "zhengqing"
}

Fk:loadTranslationTable{
  ['zhengqing'] = '争擎',
  ['@zhengqing_qing'] = '擎',
  [':zhengqing'] = '锁定技，每轮结束时，移去所有“擎”标记，然后本轮单回合内造成伤害值最多的角色获得X个“擎”标记并与你各摸一张牌（X为其该回合造成的伤害数）。若是你获得“擎”且是获得数量最多的一次，你改为摸X张牌（最多摸5）。',
  ['$zhengqing1'] = '锐势夺志，斩将者虎候是也！',
  ['$zhengqing2'] = '三军争勇，擎纛者舍我其谁！',
}

zhengqing:addEffect(fk.RoundEnd, {
  global = true,
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

    local phases = room.logic:getEventsOfScope(GameEvent.Turn, 999, Util.TrueFunc, Player.HistoryRound)
    local damageEvents = room.logic:getActualDamageEvents(999, Util.TrueFunc, Player.HistoryRound)

    if #phases > 0 and #damageEvents > 0 then
      local curIndex = 1
      local bestRecord = {}
      for i = 1, #phases do
        local records = {}
        for j = curIndex, #damageEvents do
          curIndex = j

          local phaseEvent = phases[i]
          local damageEvent = damageEvents[j]
          if phaseEvent.id < damageEvent.id and (i == #phases or phases[i + 1].id > damageEvent.id) then
            local damageData = damageEvent.data[1]
            if damageData.from then
              records[damageData.from.id] = (records[damageData.from.id] or 0) + damageData.damage
            end
          end

          if i < #phases and phases[i + 1].id < damageEvent.id then
            break
          end
        end

        for playerId, damage in pairs(records) do
          local curDMG = bestRecord.damage or 0
          if damage > curDMG then
            bestRecord = { playerIds = { playerId }, damage = damage }
          elseif damage == curDMG then
            table.insertIfNeed(bestRecord.playerIds, playerId)
          end
        end
      end

      local winnerId = table.find(bestRecord.playerIds, function(id) return id == player.id end) or table.random(bestRecord.playerIds)
      if winnerId and room:getPlayerById(winnerId):isAlive() then
        local winner = room:getPlayerById(winnerId)
        local preRecord = (player.tag["zhengqing_best"] or 0)
        room:addPlayerMark(winner, "@zhengqing_qing", bestRecord.damage)
        player.tag["zhengqing_best"] = bestRecord.damage
        if winner == player and bestRecord.damage > preRecord then
          player:drawCards(math.min(bestRecord.damage, 5), zhengqing.name)
        else
          local players = { winnerId, player.id }
          room:sortPlayersByAction(players)
          for _, p in ipairs(players) do
            room:getPlayerById(p):drawCards(1, zhengqing.name)
          end
        end
      end
    end
  end,
})

return zhengqing
