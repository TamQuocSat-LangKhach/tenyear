local jianjie = fk.CreateSkill {
  name = "jianjie"
}

Fk:loadTranslationTable{
  ['jianjie'] = '荐杰',
  ['dragon_mark_move'] = '转移“龙印”',
  ['phoenix_mark_move'] = '转移“凤印”',
  ['@@dragon_mark'] = '龙印',
  ['@@phoenix_mark'] = '凤印',
  ['#jianjie_trigger'] = '荐杰',
  ['#dragon_mark-move'] = '荐杰：令一名角色获得 %dest 的“龙印”',
  ['#phoenix_mark-move'] = '荐杰：令一名角色获得 %dest 的“凤印”',
  ['#dragon_mark-give'] = '荐杰：令一名其他角色获得“龙印”',
  ['#phoenix_mark-give'] = '荐杰：令一名其他角色获得“凤印”',
  [':jianjie'] = '①你的第一个回合开始时，你令一名其他角色获得“龙印”，然后令另一名其他角色获得“凤印”；②出牌阶段限一次（你的第一个回合除外），或当拥有“龙印”/“凤印”的角色死亡时，你可以转移“龙印”/“凤印”。<br><font color=>•拥有 “龙印”/“凤印” 的角色视为拥有技能“火计”/“连环”（均一回合限三次）；<br>•同时拥有“龙印”和“凤印”的角色视为拥有技能“业炎”，且发动“业炎”时移去“龙印”和“凤印”。<br>•你失去〖荐杰〗或死亡时移除“龙印”/“凤印”。',
  ['$jianjie1'] = '二者得一，可安天下。',
  ['$jianjie2'] = '公怀王佐之才，宜择人而仕。',
  ['$jianjie3'] = '二人齐聚，汉室可兴矣。',
}

-- Active Skill Effect
jianjie:addEffect('active', {
  anim_type = "control",
  mute = true,
  can_use = function(self, player)
    return player:getMark("jianjie-turn") == 0 and player:usedSkillTimes(jianjie.name, Player.HistoryPhase) == 0
  end,
  interaction = function()
    return UI.ComboBox {choices = {"dragon_mark_move", "phoenix_mark_move"}}
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 2,
  target_filter = function(self, player, to_select, selected)
    if #selected == 2 or not self.interaction.data then return false end
    local to = Fk:currentRoom():getPlayerById(to_select)
    local mark = (self.interaction.data == "dragon_mark_move") and "@@dragon_mark" or "@@phoenix_mark"
    if #selected == 0 then
      return to:getMark(mark) > 0
    else
      return to:getMark(mark) == 0
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, jianjie.name)
    local from = room:getPlayerById(effect.tos[1])
    local to = room:getPlayerById(effect.tos[2])
    local mark = (self.interaction.data == "dragon_mark_move") and "@@dragon_mark" or "@@phoenix_mark"
    doJianjieMarkChange(room, from, mark, false, player)
    doJianjieMarkChange(room, to, mark, true, player)
  end,
})

-- Trigger Skill Effect
jianjie:addEffect(fk.TurnStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jianjie) and player:getMark("jianjie-turn") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local gives = {}
    if target:getMark("@@dragon_mark") > 0 then
      local dra_tars = table.filter(room.alive_players, function(p) return p:getMark("@@dragon_mark") == 0 end)
      if #dra_tars > 0 then
        local tos = room:askToChoosePlayers(player, {
          targets = dra_tars,
          min_num = 1,
          max_num = 1,
          prompt = "#dragon_mark-move::"..target.id,
          skill_name = jianjie.name,
          cancelable = true,
        })
        if #tos > 0 then
          table.insert(gives, {"@@dragon_mark", tos[1]})
        end
      end
    end
    if target:getMark("@@phoenix_mark") > 0 then
      local dra_tars = table.filter(room.alive_players, function(p) return p:getMark("@@phoenix_mark") == 0 end)
      if #dra_tars > 0 then
        local tos = room:askToChoosePlayers(player, {
          targets = dra_tars,
          min_num = 1,
          max_num = 1,
          prompt = "#phoenix_mark-move::"..target.id,
          skill_name = jianjie.name,
          cancelable = true,
        })
        if #tos > 0 then
          table.insert(gives, {"@@phoenix_mark", tos[1]})
        end
      end
    end
    if #gives > 0 then
      event:setCostData(self, gives)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "jianjie")
    local dra_tars = table.filter(room:getOtherPlayers(player), function(p) return p:getMark("@@dragon_mark") == 0 end)
    local dra
    if #dra_tars > 0 then
      local tos = room:askToChoosePlayers(player, {
        targets = dra_tars,
        min_num = 1,
        max_num = 1,
        prompt = "#dragon_mark-give",
        skill_name = jianjie.name,
        cancelable = false,
      })
      if #tos > 0 then
        dra = room:getPlayerById(tos[1])
        doJianjieMarkChange(room, dra, "@@dragon_mark", true, player)
      end
    end
    local pho_tars = table.filter(room:getOtherPlayers(player), function(p) return p:getMark("@@phoenix_mark") == 0 end)
    table.removeOne(pho_tars, dra)
    if #pho_tars > 0 then
      local tos = room:askToChoosePlayers(player, {
        targets = pho_tars,
        min_num = 1,
        max_num = 1,
        prompt = "#phoenix_mark-give",
        skill_name = jianjie.name,
        cancelable = false,
      })
      if #tos > 0 then
        local pho = room:getPlayerById(tos[1])
        doJianjieMarkChange(room, pho, "@@phoenix_mark", true, player)
      end
    end
  end,
})

jianjie:addEffect(fk.Death, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jianjie) and (target:getMark("@@dragon_mark") > 0 or target:getMark("@@phoenix_mark") > 0)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local gives = {}
    if target:getMark("@@dragon_mark") > 0 then
      local dra_tars = table.filter(room.alive_players, function(p) return p:getMark("@@dragon_mark") == 0 end)
      if #dra_tars > 0 then
        local tos = room:askToChoosePlayers(player, {
          targets = dra_tars,
          min_num = 1,
          max_num = 1,
          prompt = "#dragon_mark-move::"..target.id,
          skill_name = jianjie.name,
          cancelable = true,
        })
        if #tos > 0 then
          table.insert(gives, {"@@dragon_mark", tos[1]})
        end
      end
    end
    if target:getMark("@@phoenix_mark") > 0 then
      local dra_tars = table.filter(room.alive_players, function(p) return p:getMark("@@phoenix_mark") == 0 end)
      if #dra_tars > 0 then
        local tos = room:askToChoosePlayers(player, {
          targets = dra_tars,
          min_num = 1,
          max_num = 1,
          prompt = "#phoenix_mark-move::"..target.id,
          skill_name = jianjie.name,
          cancelable = true,
        })
        if #tos > 0 then
          table.insert(gives, {"@@phoenix_mark", tos[1]})
        end
      end
    end
    if #gives > 0 then
      event:setCostData(self, gives)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "jianjie")
    for _, dat in ipairs(event:getCostData(self)) do
      local mark = dat[1]
      local p = room:getPlayerById(dat[2])
      doJianjieMarkChange(room, p, mark, true, player)
    end
  end,
})

-- Refresh Skill Effect
jianjie:addEffect(fk.TurnStart, {
  global = false,
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(jianjie,true) and target == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local current_event = room.logic:getCurrentEvent()
    if not current_event then return end
    local turn_event = current_event:findParent(GameEvent.Turn, true)
    if not turn_event then return end
    local events = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
    for _, e in ipairs(events) do
      local current_player = e.data[1]
      if current_player == player then
        if turn_event.id == e.id then
          room:setPlayerMark(player, "jianjie-turn", 1)
        end
        break
      end
    end
  end,
})

jianjie:addEffect(fk.EventAcquireSkill, {
  global = false,
  can_refresh = function (self, event, target, player, data)
    return target == player and data == jianjie and player.room:getBanner("RoundCount")
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local current_event = room.logic:getCurrentEvent()
    if not current_event then return end
    local turn_event = current_event:findParent(GameEvent.Turn, true)
    if not turn_event then return end
    local events = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
    for _, e in ipairs(events) do
      local current_player = e.data[1]
      if current_player == player then
        if turn_event.id == e.id then
          room:setPlayerMark(player, "jianjie-turn", 1)
        end
        break
      end
    end
  end,
})

jianjie:addEffect(fk.EventLoseSkill, {
  global = false,
  can_refresh = function (self, event, target, player, data)
    return data == jianjie and (player:getMark("@@dragon_mark") > 0 or player:getMark("@@phoenix_mark") > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    doJianjieMarkChange(room, player, "@@dragon_mark", false)
    doJianjieMarkChange(room, player, "@@phoenix_mark", false)
  end,
})

jianjie:addEffect(fk.BuryVictim, {
  global = false,
  can_refresh = function (self, event, target, player, data)
    return (target == player or target:hasSkill(jianjie, true, true)) and (player:getMark("@@dragon_mark") > 0 or player:getMark("@@phoenix_mark") > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    doJianjieMarkChange(room, player, "@@dragon_mark", false)
    doJianjieMarkChange(room, player, "@@phoenix_mark", false)
  end,
})

return jianjie
