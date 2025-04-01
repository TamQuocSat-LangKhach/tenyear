local bihuo = fk.CreateSkill {
  name = "bihuo",
}

Fk:loadTranslationTable{
  ["bihuo"] = "避祸",
  [":bihuo"] = "当你受到其他角色造成的伤害后，你可以令一名角色下回合摸牌阶段摸牌数+1；当你对其他角色造成伤害后，你可以令一名角色下回合"..
  "摸牌阶段摸牌数-1。",

  ["#bihuo-plus"] = "避祸：你可以令一名角色下回合摸牌阶段摸牌数+1",
  ["#bihuo-minus"] = "避祸：你可以令一名角色下回合摸牌阶段摸牌数-1",
  ["@bihuo"] = "避祸",
  ["@bihuo-turn"] = "避祸",

  ["$bihuo1"] = "董卓乱政，京师不可久留。",
  ["$bihuo2"] = "权臣当朝，不如早日脱身。",
}

bihuo:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bihuo.name) and data.to ~= player
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      skill_name = bihuo.name,
      prompt = "#bihuo-minus",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(to, "@bihuo", to:getMark("@bihuo") - 1)
  end,
})

bihuo:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bihuo.name) and data.from and data.from ~= player
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      skill_name = bihuo.name,
      prompt = "#bihuo-plus",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(to, "@bihuo", to:getMark("@bihuo") + 1)
  end,
})

bihuo:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@bihuo") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@bihuo-turn", player:getMark("@bihuo"))
    room:setPlayerMark(player, "@bihuo", 0)
  end,
})

bihuo:addEffect(fk.DrawNCards, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@bihuo-turn") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@bihuo-turn")
  end,
})

return bihuo
