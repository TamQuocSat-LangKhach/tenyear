local shexue = fk.CreateSkill {
  name = "shexue",
}

Fk:loadTranslationTable{
  ["shexue"] = "设学",
  [":shexue"] = "出牌阶段开始时，你可以将一张牌当上个回合角色出牌阶段内使用过的一张基本牌或普通锦囊牌使用（无距离限制）；出牌阶段结束时，"..
  "你可以令下个回合角色于其出牌阶段开始时可以将一张牌当你本阶段使用过的一张基本牌或普通锦囊牌使用（无距离限制）。",

  ["#shexue-use"] = "设学：你可以将一张牌当上回合出牌阶段内使用过的牌使用",
  ["#shexue-invoke"] = "设学：你可以令下回合角色出牌阶段开始时可以将一张牌当你本阶段使用过的牌使用",

  ["$shexue1"] = "虽为武夫，亦需极目汗青。",
  ["$shexue2"] = "武可靖天下，然不能定天下。",
}

shexue:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play and
      (player:hasSkill(shexue.name) or player:getMark("shexue_invoking-turn") ~= 0) then
      if player:isNude() and #player:getHandlyIds() == 0 then return end
      local room = player.room
      local names = player:getTableMark("shexue_invoking-turn")
      if player:hasSkill(shexue.name) then
        if type(player:getMark("shexue_last-turn")) ~= "table" then
          local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
          if not turn_event then return end
          local turn_events = room.logic:getEventsByRule(GameEvent.Turn, 1, function (e)
            return e.id < turn_event.id
          end, 0)
          if #turn_events == 0 then return end
          turn_event = turn_events[1]
          local last_player = turn_event.data.who
          local phase_events_dat = {}
          room.logic:getEventsByRule(GameEvent.Phase, 1, function (e)
            if e.data.phase == Player.Play and e.data.who == last_player and e.id < turn_event.end_id then
              table.insert(phase_events_dat, {e.id, e.end_id})
            end
          end, turn_event.id)
          if #phase_events_dat == 0 then return end
          room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
            if table.find(phase_events_dat, function (dat)
              return e.id > dat[1] and e.id < dat[2]
            end) then
              local use = e.data
              if use.from == last_player and (use.card.type == Card.TypeBasic or use.card:isCommonTrick()) then
                table.insertIfNeed(names, use.card.name)
              end
            end
          end, turn_event.id)
        end
        room:setPlayerMark(player, "shexue_last-turn", names)
      end
      names = table.filter(names, function (name)
        local card = Fk:cloneCard(name)
        card.skillName = shexue.name
        return player:canUse(card, { bypass_times = true, bypass_distances = true })
      end)
      if #names > 0 then
        event:setCostData(self, {choice = names})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_names = table.filter(Fk.all_card_names, function (name)
      return table.contains(event:getCostData(self).choice, name)
    end)
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "shexue_viewas",
      prompt = "#shexue-use",
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        all_names = all_names,
      },
    })
    if success and dat then
      event:setCostData(self, {extra_data = dat})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self).extra_data
    local card = Fk:cloneCard(dat.interaction)
    card.skillName = shexue.name
    card:addSubcards(dat.cards)
    room:useCard{
      from = player,
      tos = dat.targets,
      card = card,
      extraUse = true,
    }
  end,
})

shexue:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shexue.name) and player.phase == Player.Play and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == player then
          return use.card.type == Card.TypeBasic or use.card:isCommonTrick()
        end
      end, Player.HistoryPhase) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = shexue.name,
      prompt = "#shexue-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = room:getBanner(shexue.name) or {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player and (use.card.type == Card.TypeBasic or use.card:isCommonTrick()) then
        table.insertIfNeed(names, use.card.name)
      end
    end, Player.HistoryPhase)
    room:setBanner(shexue.name, names)
  end,
})

shexue:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room:getBanner(shexue.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "shexue_invoking-turn", room:getBanner(shexue.name))
    room:setBanner(shexue.name, nil)
  end,
})

return shexue
