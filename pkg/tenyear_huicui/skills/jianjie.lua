local jianjie = fk.CreateSkill {
  name = "jianjie",
}

Fk:loadTranslationTable{
  ["jianjie"] = "荐杰",
  [":jianjie"] = "你的第一个回合开始时，你令一名其他角色获得“龙印”，然后令另一名其他角色获得“凤印”；<br>"..
  "出牌阶段限一次（你的第一个回合除外），或当拥有“龙印”/“凤印”的角色死亡时，你可以转移“龙印”/“凤印”。<br>"..
  "<font color=>•拥有 “龙印”/“凤印” 的角色视为拥有技能“火计”/“连环”（均一回合限三次）；<br>"..
  "•同时拥有“龙印”和“凤印”的角色视为拥有技能“业炎”，且发动“业炎”时移去“龙印”和“凤印”。<br>"..
  "•你失去〖荐杰〗或死亡时移除“龙印”/“凤印”。",

  ["@@dragon_mark"] = "龙印",
  ["@@phoenix_mark"] = "凤印",
  ["dragon_mark_move"] = "转移“龙印”",
  ["phoenix_mark_move"] = "转移“凤印”",
  ["#dragon_mark-move"] = "荐杰：令一名角色获得 %dest 的“龙印”",
  ["#phoenix_mark-move"] = "荐杰：令一名角色获得 %dest 的“凤印”",
  ["#dragon_mark-give"] = "荐杰：令一名其他角色获得“龙印”",
  ["#phoenix_mark-give"] = "荐杰：令一名其他角色获得“凤印”",

  ["$jianjie1"] = "二者得一，可安天下。",
  ["$jianjie2"] = "公怀王佐之才，宜择人而仕。",
  ["$jianjie3"] = "二人齐聚，汉室可兴矣。",
}

local doJianjieMarkChange = function (room, player, mark, acquired, proposer)
  local skill = (mark == "@@dragon_mark") and "jj__huoji&" or "jj__lianhuan&"
  room:setPlayerMark(player, mark, acquired and 1 or 0)
  if not acquired then skill = "-"..skill end
  room:handleAddLoseSkills(player, skill, nil, false)
  local double_mark = (player:getMark("@@dragon_mark") > 0 and player:getMark("@@phoenix_mark") > 0)
  local yy_skill = double_mark and "jj__yeyan&" or "-jj__yeyan&"
  room:handleAddLoseSkills(player, yy_skill, nil, false)
  if acquired then
    proposer:broadcastSkillInvoke("jianjie", double_mark and 3 or math.random(2))
  end
end

jianjie:addEffect("active", {
  anim_type = "control",
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
    if #selected == 2 or not self.interaction.data then return end
    local mark = (self.interaction.data == "dragon_mark_move") and "@@dragon_mark" or "@@phoenix_mark"
    if #selected == 0 then
      return to_select:getMark(mark) > 0
    else
      return to_select:getMark(mark) == 0
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local from = effect.tos[1]
    local to = effect.tos[2]
    local mark = (self.interaction.data == "dragon_mark_move") and "@@dragon_mark" or "@@phoenix_mark"
    doJianjieMarkChange(room, from, mark, false, player)
    doJianjieMarkChange(room, to, mark, true, player)
  end,
})

jianjie:addEffect(fk.TurnStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianjie.name) and player:getMark("jianjie-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:getMark("@@dragon_mark") == 0
    end)
    local to
    if #targets > 0 then
      to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#dragon_mark-give",
        skill_name = jianjie.name,
        cancelable = false,
      })[1]
      doJianjieMarkChange(room, to, "@@dragon_mark", true, player)
    end
    targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:getMark("@@phoenix_mark") == 0
    end)
    table.removeOne(targets, to)
    if #targets > 0 then
      to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#phoenix_mark-give",
        skill_name = jianjie.name,
        cancelable = false,
      })[1]
      doJianjieMarkChange(room, to, "@@phoenix_mark", true, player)
    end
  end,

  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(jianjie.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local turn_events = room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
      return e.data.who == player
    end, Player.HistoryGame)
    if #turn_events == 1 and turn_events[1].data == data then
      room:setPlayerMark(player, "jianjie-turn", 1)
    end
  end,
})

jianjie:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jianjie.name) and (target:getMark("@@dragon_mark") > 0 or target:getMark("@@phoenix_mark") > 0)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local gives = {}
    if target:getMark("@@dragon_mark") > 0 then
      local targets = table.filter(room.alive_players, function(p)
        return p:getMark("@@dragon_mark") == 0
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#dragon_mark-move::"..target.id,
          skill_name = jianjie.name,
          cancelable = true,
        })
        if #to > 0 then
          table.insert(gives, {"@@dragon_mark", to[1]})
        end
      end
    end
    if target:getMark("@@phoenix_mark") > 0 then
      local targets = table.filter(room.alive_players, function(p)
        return p:getMark("@@phoenix_mark") == 0
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#phoenix_mark-move::"..target.id,
          skill_name = jianjie.name,
          cancelable = true,
        })
        if #to > 0 then
          table.insert(gives, {"@@phoenix_mark", to[1]})
        end
      end
    end
    if #gives > 0 then
      event:setCostData(self, {extra_data = gives})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, dat in ipairs(event:getCostData(self).extra_data) do
      local mark = dat[1]
      local p = dat[2]
      doJianjieMarkChange(room, p, mark, true, player)
    end
  end,
})

jianjie:addAcquireEffect(function (self, player, is_start)
  if not is_start and player.room.current == player then
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event ~= nil then
      local turn_events = room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
        return e.data.who == player
      end, Player.HistoryGame)
      if #turn_events == 1 and turn_events[1] == turn_event then
        room:setPlayerMark(player, "jianjie-turn", 1)
      end
    end
  end
end)

jianjie:addEffect(fk.BuryVictim, {
  can_refresh = function (self, event, target, player, data)
    return (target == player or target:hasSkill(jianjie.name, true, true)) and
      (player:getMark("@@dragon_mark") > 0 or player:getMark("@@phoenix_mark") > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    doJianjieMarkChange(room, player, "@@dragon_mark", false)
    doJianjieMarkChange(room, player, "@@phoenix_mark", false)
  end,
})

jianjie:addLoseEffect(function (self, player, is_death)
  local room = player.room
  doJianjieMarkChange(room, player, "@@dragon_mark", false)
  doJianjieMarkChange(room, player, "@@phoenix_mark", false)
end)

return jianjie
