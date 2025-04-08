local wumei = fk.CreateSkill {
  name = "wumei",
}

Fk:loadTranslationTable{
  ["wumei"] = "寤寐",
  [":wumei"] = "每轮限一次，回合开始前，你可以令一名角色执行一个额外的回合：该回合结束阶段，所有存活角色将体力值调整为此额外回合开始时的数值。",

  ["@@wumei_extra-turn"] = "寤寐",
  ["#wumei-choose"] = "寤寐：你可以令一名角色执行一个额外的回合",

  ["$wumei1"] = "大梦若期，皆付一枕黄粱。",
  ["$wumei2"] = "日所思之，故夜所梦之。",
}

wumei:addEffect(fk.BeforeTurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wumei.name) and
      player:usedSkillTimes(wumei.name, Player.HistoryRound) == 0 and
      table.find(player.room.alive_players, function (p)
        return p:getMark("@@wumei_extra-turn") == 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getMark("@@wumei_extra-turn") == 0
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#wumei-choose",
      skill_name = wumei.name
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addPlayerMark(to, "@@wumei_extra-turn", 1)
    local hp_record = {}
    for _, p in ipairs(room.alive_players) do
      table.insert(hp_record, {p.id, p.hp})
    end
    room:setBanner("wumei_record-turn", hp_record)
    to:gainAnExtraTurn()
  end,
})

wumei:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:getMark("@@wumei_extra-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, wumei.name, "special")
    local hp_record = room:getBanner("wumei_record-turn")
    if type(hp_record) ~= "table" then return false end
    for _, p in ipairs(room:getAlivePlayers()) do
      local p_record = table.find(hp_record, function (sub_record)
        return #sub_record == 2 and sub_record[1] == p.id
      end)
      if p_record then
        p.hp = math.min(p.maxHp, p_record[2])
        room:broadcastProperty(p, "hp")
      end
    end
  end,
})

return wumei
