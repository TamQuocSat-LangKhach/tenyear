local shengdu = fk.CreateSkill {
  name = "shengdu"
}

Fk:loadTranslationTable{
  ['shengdu'] = '生妒',
  ['@shengdu'] = '生妒',
  ['#shengdu-choose'] = '生妒：选择一名角色，其下次摸牌阶段摸牌后，你摸等量的牌',
  [':shengdu'] = '回合开始时，你可以选择一名没有“生妒”标记的其他角色，该角色获得“生妒”标记。有“生妒”标记的角色摸牌阶段摸牌后，每有一个“生妒”你摸等量的牌，然后移去“生妒”标记。',
  ['$shengdu1'] = '姐姐有的，妹妹也要有。',
  ['$shengdu2'] = '你我同为佳丽，凭甚汝得独宠？',
}

-- 触发技效果
shengdu:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shengdu.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local p = room:askToChoosePlayers(player, {
      targets = table.map(table.filter(room.alive_players, function (p)
        return p ~= player and p:getMark("@shengdu") == 0
      end), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#shengdu-choose",
      skill_name = shengdu.name,
    })
    if #p > 0 then
      event:setCostData(self, p[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(room:getPlayerById(event:getCostData(self)), "@shengdu")
  end,
})

-- 触发技效果
shengdu:addEffect(fk.AfterDrawNCards, {
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@shengdu") > 0 and data.n > 0 and player:hasSkill(shengdu.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(data.n * target:getMark("@shengdu"), shengdu.name)
    room:setPlayerMark(target, "@shengdu", 0)
  end,
})

-- 刷新效果
shengdu:addEffect(fk.BuryVictim, {
  can_refresh = function(self, event, target, player, data)
    if player ~= target then return false end
    return table.every(player.room.alive_players, function (p)
      return not p:hasSkill(shengdu.name, true)
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@shengdu", 0)
    end
  end,
})

-- 刷新效果
shengdu:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    if player ~= target then return false end
    return table.every(player.room.alive_players, function (p)
      return not p:hasSkill(shengdu.name, true)
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@shengdu", 0)
    end
  end,
})

return shengdu
