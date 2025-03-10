local shexue = fk.CreateSkill {
  name = "shexuse"
}

Fk:loadTranslationTable{
  ['shexue'] = '设学',
  ['shexue_viewas'] = '设学',
  ['#shexue-use'] = '是否使用 设学，将一张牌当上个回合角色出牌阶段内使用过的牌使用',
  ['#shexue-invoke'] = '是否使用 设学，令下回合角色出牌阶段开始时可以将一张牌当你本阶段使用过的牌使用',
  [':shexue'] = '出牌阶段开始时，你可以将一张牌当上个回合角色出牌阶段内使用过的一张基本牌或普通锦囊牌使用（无距离限制）；出牌阶段结束时，你可以令下个回合角色于其出牌阶段开始时可以将一张牌当你本阶段使用过的一张基本牌或普通锦囊牌使用（无距离限制）。',
  ['$shexue1'] = '虽为武夫，亦需极目汗青。',
  ['$shexue2'] = '武可靖天下，然不能定天下。',
}

shexue:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player)
    if target.phase == Player.Play and player:hasSkill(shexue.name) then
      if target:isNude() then return false end
      local room = player.room
      if player == target then
        local all_names = player:getMark("shexue_last-turn")
        if type(all_names) ~= "table" then
          all_names = {}
          local logic = room.logic
          local turn_event = logic:getCurrentEvent():findParent(GameEvent.Turn)
          if not turn_event then return false end
          local all_turn_events = logic.event_recorder[GameEvent.Turn]
          if type(all_turn_events) == "table" and #all_turn_events > 1 then
            turn_event = all_turn_events[#all_turn_events - 1]
            local last_player = turn_event.data[1]
            local all_phase_events = logic.event_recorder[GameEvent.Phase]
            if type(all_phase_events) == "table" then
              local play_ids = {}
              for i = #all_phase_events, 1, -1 do
                local e = all_phase_events[i]
                if e.id < turn_event.id then break end
                if e.id < turn_event.end_id and e.data[2] == Player.Play then
                  table.insert(play_ids, {e.id, e.end_id})
                end
              end
              if #play_ids > 0 then
                room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
                  local in_play = false
                  for _, ids in ipairs(play_ids) do
                    if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
                      in_play = true
                      break
                    end
                  end
                  if in_play then
                    local use = e.data[1]
                    if use.from == last_player.id and (use.card.type == Card.TypeBasic or use.card:isCommonTrick()) then
                      table.insertIfNeed(all_names, use.card.name)
                    end
                  end
                end, turn_event.id)
              end
            end
          end
        end
        room:setPlayerMark(player, "shexue_last-turn", all_names)
      end
      local extra_data = {bypass_times = true, bypass_distances = true}
      local names = table.filter(all_names, function (n)
        local card = Fk:cloneCard(n)
        card.skillName = shexue.name
        return card.skill:canUse(player, card, extra_data) and not player:prohibitUse(card)
          and table.find(room.alive_players, function (p)
            return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player, card, false)
          end)
      end)
      if #names > 0 then
        extra_data.virtualuse_allnames = all_names
        extra_data.virtualuse_names = names
        event:setCostData(skill, extra_data)
        return true
      end
    elseif not target.dead then
      local all_names = player:getTableMark("shexue_invoking-turn")
      if #all_names == 0 then return false end
      local extra_data = {bypass_times = true, bypass_distances = true}
      local names = table.filter(all_names, function (n)
        local card = Fk:cloneCard(n)
        card.skillName = shexue.name
        return card.skill:canUse(target, card, extra_data) and not target:prohibitUse(card)
          and table.find(room.alive_players, function (p)
            return not target:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, target, card, false)
          end)
      end)
      if #names > 0 then
        extra_data.virtualuse_allnames = all_names
        extra_data.virtualuse_names = names
        event:setCostData(skill, extra_data)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    if player == target then
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "shexue_viewas",
        prompt = "#shexue-use",
        cancelable = true,
        extra_data = event:getCostData(skill),
      })
      if success then
        event:setCostData(skill, dat)
        return true
      end
    else
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if player == target then
      local dat = table.simpleClone(event:getCostData(skill))
      local card = Fk:cloneCard(dat.interaction)
      card:addSubcards(dat.cards)
      card.skillName = shexue.name
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
      if player.dead or player ~= target then return false end
      local all_names = player:getTableMark("shexue_invoking-turn")
      if #all_names == 0 then return false end
      local extra_data = {bypass_times = true, bypass_distances = true}
      local names = table.filter(all_names, function (n)
        local card = Fk:cloneCard(n)
        card.skillName = shexue.name
        return card.skill:canUse(player, card, extra_data) and not player:prohibitUse(card)
          and table.find(room.alive_players, function (p)
            return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player, card, false)
          end)
      end)
      if #names == 0 then return false end
      extra_data.virtualuse_allnames = all_names
      extra_data.virtualuse_names = names
      dat = extra_data
    end
    local success, dat2 = room:askToUseActiveSkill(target, {
      skill_name = "shexue_viewas",
      prompt = "#shexue-use",
      cancelable = true,
      extra_data = dat,
    })
    if success and dat2 then
      local card = Fk:cloneCard(dat2.interaction)
      card:addSubcards(dat2.cards)
      card.skillName = shexue.name
      room:useCard{
        from = target.id,
        tos = table.map(dat2.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    end
  end,
})

shexue:addEffect(fk.EventPhaseEnd, {
  global = false,
  can_trigger = function(self, event, target, player)
    if player.phase == Player.Play and player:hasSkill(shexue.name) then
      local room = player.room
      if not player.dead then
        local all_names = player:getTableMark("shexue_invoking-turn")
        if #all_names > 0 then
          local extra_data = {bypass_times = true, bypass_distances = true}
          local names = table.filter(all_names, function (n)
            local card = Fk:cloneCard(n)
            card.skillName = shexue.name
            return card.skill:canUse(player, card, extra_data) and not player:prohibitUse(card)
              and table.find(room.alive_players, function (p)
                return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player, card, false)
              end)
          end)
          if #names > 0 then
            extra_data.virtualuse_allnames = all_names
            extra_data.virtualuse_names = names
            event:setCostData(skill, extra_data)
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    return room:askToSkillInvoke(player, {
      skill_name = shexue.name,
      prompt = "#shexue-invoke",
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "shexue_invoking", table.simpleClone(event:getCostData(skill)))
  end,
})

shexue:addEffect(fk.TurnStart, {
  global = false,
  can_refresh = function(self, event, target, player)
    return player:getMark("shexue_invoking") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "shexue_invoking-turn", player:getMark("shexue_invoking"))
    room:setPlayerMark(player, "shexue_invoking", 0)
  end,
})

return shexue
