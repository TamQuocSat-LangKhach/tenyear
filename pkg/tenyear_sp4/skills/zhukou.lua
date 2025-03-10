local zhukou = fk.CreateSkill {
  name = "zhukou"
}

Fk:loadTranslationTable{
  ['zhukou'] = '逐寇',
  ['#zhukou-choose'] = '是否发动逐寇，选择2名其他角色，对其各造成1点伤害',
  [':zhukou'] = '当你于每回合的出牌阶段第一次造成伤害后，你可以摸X张牌（X为本回合你已使用的牌数）。结束阶段，若你本回合未造成过伤害，你可以对两名其他角色各造成1点伤害。',
  ['$zhukou1'] = '草莽贼寇，不过如此。',
  ['$zhukou2'] = '轻装上阵，利剑出鞘。',
}

zhukou:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhukou.name) then
      local room = player.room
      if room.current and room.current.phase == Player.Play then
        local damage_event = room.logic:getCurrentEvent()
        if not damage_event then return false end
        local x = player:getMark("zhukou_record-phase")
        if x == 0 then
          room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
            local reason = e.data[3]
            if reason == "damage" then
              local first_damage_event = e:findParent(GameEvent.Damage)
              if first_damage_event and first_damage_event.data[1].from == player then
                x = first_damage_event.id
                room:setPlayerMark(player, "zhukou_record-phase", x)
              end
              return true
            end
          end, Player.HistoryPhase)
        end
        if damage_event.id == x then
          local events = room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
          local end_id = player:getMark("zhukou_record-turn")
          if end_id == 0 then
            local turn_event = damage_event:findParent(GameEvent.Turn, false)
            end_id = turn_event.id
          end
          room:setPlayerMark(player, "zhukou_record-turn", room.logic.current_event_id)
          local y = player:getMark("zhukou_usecard-turn")
          for i = #events, 1, -1 do
            local e = events[i]
            if e.id <= end_id then break end
            local use = e.data[1]
            if use.from == player.id then
              y = y + 1
            end
          end
          room:setPlayerMark(player, "zhukou_usecard-turn", y)
          return y > 0
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      return room:askToSkillInvoke(player, {skill_name = zhukou.name})
    else
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      if #targets < 2 then return end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 2,
        max_num = 2,
        prompt = "#zhukou-choose",
        skill_name = zhukou.name,
        cancelable = true
      })
      if #tos == 2 then
        event:setCostData(skill, tos)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local x = player:getMark("zhukou_usecard-turn")
    if x > 0 then
      player:drawCards(x, zhukou.name)
    end
  end,
})

zhukou:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if player.phase == Player.Finish and #player.room.alive_players > 2 then
      if player:getMark("zhukou_damaged-turn") > 0 then return false end
      local events = player.room.logic.event_recorder[GameEvent.ChangeHp] or Util.DummyTable
      local end_id = player:getMark("zhukou_damage_record-turn")
      if end_id == 0 then
        local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
        end_id = turn_event.id
      end
      player.room:setPlayerMark(player, "zhukou_damage_record-turn", player.room.logic.current_event_id)
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id <= end_id then break end
        local damage = e.data[5]
        if damage and damage.from == player then
          player.room:setPlayerMark(player, "zhukou_damaged-turn", 1)
          return false
        end
      end
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    if #targets < 2 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 2,
      max_num = 2,
      prompt = "#zhukou-choose",
      skill_name = zhukou.name,
      cancelable = true
    })
    if #tos == 2 then
      event:setCostData(skill, tos)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(skill)) do
      local tar = room:getPlayerById(p)
      if not tar.dead then
        room:damage{
          from = player,
          to = tar,
          damage = 1,
          skill_name = zhukou.name,
        }
      end
    end
  end,
})

return zhukou
