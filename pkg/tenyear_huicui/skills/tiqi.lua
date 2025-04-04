local tiqi = fk.CreateSkill {
  name = "tiqi",
}

Fk:loadTranslationTable{
  ["tiqi"] = "涕泣",
  [":tiqi"] = "其他角色的出牌阶段开始前，若其本回合额定摸牌阶段摸牌数不为2，则你摸此摸牌数与2之差的牌，然后可以令其本回合手牌上限"..
  "增加或减少同样的数值。",

  ["tiqi_add"] = "%dest本回合手牌上限+%arg",
  ["tiqi_minus"] = "%dest本回合手牌上限-%arg",

  ["$tiqi1"] = "远望中原，涕泪交流。",
  ["$tiqi2"] = "瞻望家乡，泣涕如雨。",
}

tiqi:addEffect(fk.EventPhaseChanging, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tiqi.name) and target ~= player and data.phase > Player.Draw and
      player:usedSkillTimes(tiqi.name, Player.HistoryTurn) == 0 then
      local phase_events = player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
        local phase = e.data
        return phase.phase == Player.Draw and phase.who == target and phase.reason == "game_rule" and
          not phase.skipped
      end, Player.HistoryTurn)
      if #phase_events == 0 then
        event:setCostData(self, {tos = {target}, choice = 2})
        return true
      end
      local phase = phase_events[1]
      local n = 0
      player.room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        if e.id < phase.end_id then
          for _, move in ipairs(e.data) do
            if move.to == target and move.moveReason == fk.ReasonDraw then
              n = n + #move.moveInfo
            end
          end
        end
      end, phase.id)
      if n ~= 2 then
        event:setCostData(self, {tos = {target}, choice = math.abs(n - 2)})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).choice
    player:drawCards(n, tiqi.name)
    if player.dead or target.dead then return end
    local choice = room:askToChoice(player, {
      choices = {"tiqi_add::"..target.id..":"..n, "tiqi_minus::"..target.id..":"..n, "Cancel"},
      skill_name = tiqi.name,
    })
    if choice ~= "Cancel" then
      if choice:startsWith("tiqi_add") then
        room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, n)
      else
        room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, n)
      end
    end
  end,
})

return tiqi
