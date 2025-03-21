local wumei = fk.CreateSkill {
  name = "wumei"
}

Fk:loadTranslationTable{
  ['wumei'] = '寤寐',
  ['@@wumei_extra'] = '寤寐',
  ['#wumei-choose'] = '寤寐: 你可以令一名角色执行一个额外的回合',
  ['#wumei_delay'] = '寤寐',
  [':wumei'] = '每轮限一次，回合开始前，你可以令一名角色执行一个额外的回合：该回合结束时，将所有存活角色的体力值调整为此额外回合开始时的数值。',
  ['$wumei1'] = '大梦若期，皆付一枕黄粱。',
  ['$wumei2'] = '日所思之，故夜所梦之。',
}

wumei:addEffect(fk.BeforeTurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wumei.name) and player:usedSkillTimes(wumei.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = table.map(table.filter(room.alive_players, function (p)
        return p:getMark("@@wumei_extra") == 0 
      end), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#wumei-choose",
      skill_name = wumei.name
    })
    if #to > 0 then
      event:setCostData(skill, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))
    room:addPlayerMark(to, "@@wumei_extra", 1)
    local hp_record = {}
    for _, p in ipairs(room.alive_players) do
      table.insert(hp_record, {p.id, p.hp})
    end
    room:setPlayerMark(to, "wumei_record", hp_record)
    to:gainAnExtraTurn()
  end,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@wumei_extra") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@wumei_extra", 0)
    room:setPlayerMark(player, "wumei_record", 0)
  end,
})

local wumei_delay = fk.CreateTriggerSkill{
  name = "#wumei_delay",
  events = {fk.EventPhaseStart},
  mute = true,
}

wumei:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Finish and player:getMark("@@wumei_extra") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, wumei.name, "special")
    local hp_record = player:getMark("wumei_record")
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
