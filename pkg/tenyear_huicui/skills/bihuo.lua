local bihuo = fk.CreateSkill {
  name = "bihuo"
}

Fk:loadTranslationTable{
  ['bihuo'] = '避祸',
  ['#bihuo-plus'] = '避祸：你可以令一名角色下回合摸牌阶段摸牌数+1',
  ['#bihuo-minus'] = '避祸：你可以令一名角色下回合摸牌阶段摸牌数-1',
  ['@bihuo'] = '避祸',
  ['@bihuo-turn'] = '避祸',
  [':bihuo'] = '当你受到其他角色造成的伤害后，你可令一名角色下回合摸牌阶段摸牌数+1；当你对其他角色造成伤害后，你可令一名角色下回合摸牌阶段摸牌数-1。',
  ['$bihuo1'] = '董卓乱政，京师不可久留。',
  ['$bihuo2'] = '权臣当朝，不如早日脱身。',
}

bihuo:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bihuo) and data.from and data.from ~= data.to
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#bihuo-minus"
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      skill_name = bihuo.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(bihuo.name)
    local to = room:getPlayerById(event:getCostData(self))
    room:notifySkillInvoked(player, bihuo.name, "control")
    room:setPlayerMark(to, "@bihuo", to:getMark("@bihuo") - 1)
  end,
})

bihuo:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bihuo) and data.from and data.from ~= data.to
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#bihuo-plus"
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      skill_name = bihuo.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(bihuo.name)
    local to = room:getPlayerById(event:getCostData(self))
    room:notifySkillInvoked(player, bihuo.name, "support")
    room:setPlayerMark(to, "@bihuo", to:getMark("@bihuo") + 1)
  end,
})

bihuo:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@bihuo") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@bihuo-turn", player:getMark("@bihuo"))
    room:setPlayerMark(player, "@bihuo", 0)
  end,
})

bihuo:addEffect(fk.DrawNCards, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@bihuo-turn") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.n = data.n + player:getMark("@bihuo-turn")
  end,
})

return bihuo
