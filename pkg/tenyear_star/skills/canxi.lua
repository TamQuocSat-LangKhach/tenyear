local canxi = fk.CreateSkill {
  name = "canxi"
}

Fk:loadTranslationTable{
  ['canxi'] = '残玺',
  ['@canxi1-round'] = '「妄生」',
  ['@canxi2-round'] = '「向死」',
  ['@canxi_exist_kingdoms'] = '',
  ['#canxi-choice1'] = '残玺：选择本轮生效的“玺角”势力',
  ['canxi1'] = '「妄生」',
  ['canxi2'] = '「向死」',
  ['#canxi-choice2'] = '残玺：选择本轮对 %arg 势力角色生效的效果',
  [':canxi'] = '锁定技，游戏开始时，你获得场上各势力的“玺角”标记，其中魏、蜀、吴、群每少一个势力你加1点体力上限。每轮开始时，你选择一个“玺角”势力并选择一个效果生效直到下轮开始：<br>「妄生」：该势力角色每回合首次造成伤害+1，计算与其他角色距离-1；<br>「向死」：该势力其他角色每回合首次回复体力后失去1点体力，每回合对你使用的第一张牌无效。',
  ['$canxi1'] = '大势散于天下，全宝玺者其谁？',
  ['$canxi2'] = '汉祚已僵待死，吾可取而代之。',
}

canxi:addEffect(fk.DamageCaused, {
  can_trigger = function (self, event, target, player)
    if not player:hasSkill(canxi.name) then return false end
    return target and player:getMark("@canxi1-round") == target.kingdom and
      not table.contains(player:getTableMark("canxi1-turn"), target.id)
  end,
  on_use = function (self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(canxi.name)
    room:notifySkillInvoked(player, canxi.name, "offensive")
    room:addTableMark(player, "canxi1-turn", target.id)
    data.damage = data.damage + 1
  end,
})

canxi:addEffect(fk.HpRecover, {
  can_trigger = function (self, event, target, player)
    if not player:hasSkill(canxi.name) then return false end
    return player:getMark("@canxi2-round") == target.kingdom and
      not target.dead and target ~= player and not table.contains(player:getTableMark("canxi21-turn"), target.id)
  end,
  on_use = function (self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(canxi.name)
    room:notifySkillInvoked(player, canxi.name, "control")
    room:addTableMark(player, "canxi21-turn", target.id)
    room:loseHp(target, 1, canxi.name)
  end,
})

canxi:addEffect(fk.TargetConfirmed, {
  can_trigger = function (self, event, to_select, player, data)
    if not player:hasSkill(canxi.name) then return false end
    if player == to_select and data.from ~= player.id then
      local p = player.room:getPlayerById(data.from)
      return player:getMark("@canxi2-round") == p.kingdom and not table.contains(player:getTableMark("canxi22-turn"), p.id)
    end
  end,
  on_use = function (self, event, to_select, player, data)
    local room = player.room
    player:broadcastSkillInvoke(canxi.name)
    room:notifySkillInvoked(player, canxi.name, "defensive")
    room:addTableMark(player, "canxi22-turn", data.from)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
})

canxi:addEffect(fk.RoundStart, {
  can_trigger = function (self, event, target, player)
    if not player:hasSkill(canxi.name) then return false end
    return #player:getTableMark("@canxi_exist_kingdoms") > 0
  end,
  on_use = function (self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(canxi.name)
    room:notifySkillInvoked(player, canxi.name, "special")
    local choice1 = room:askToChoice(player, {
      choices = player:getMark("@canxi_exist_kingdoms"),
      skill_name = canxi.name,
      prompt = "#canxi-choice1",
    })
    local choice2 = room:askToChoice(player, {
      choices = {"canxi1", "canxi2"},
      skill_name = canxi.name,
      prompt = "#canxi-choice2:::"..choice1,
      cancelable = true
    })
    room:setPlayerMark(player, "@"..choice2.."-round", choice1)
  end,
})

canxi:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player)
    if not player:hasSkill(canxi.name) then return false end
    return true
  end,
  on_use = function (self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(canxi.name)
    room:notifySkillInvoked(player, canxi.name, "special")
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    room:setPlayerMark(player, "@canxi_exist_kingdoms", kingdoms)
    local n = #table.filter({"wei", "shu", "wu", "qun"}, function(s)
      return not table.contains(kingdoms, s)
    end)
    if n > 0 then
      room:changeMaxHp(player, n)
    end
  end,
})

canxi:addEffect(fk.LoseSkill, {
  on_lose = function (self, player, is_death)
    local room = player.room
    room:setPlayerMark(player, "@canxi_exist_kingdoms", 0)
    room:setPlayerMark(player, "@canxi1-round", 0)
    room:setPlayerMark(player, "@canxi2-round", 0)
  end,
})

local canxi_distance = fk.CreateSkill{
  name = "#canxi_distance"
}
canxi_distance:addEffect(fk.GlobalDistance, {
  correct_func = function(self, from, to)
    return -#table.filter(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(canxi) and p:getMark("@canxi1-round") == from.kingdom
    end)
  end,
})

return canxi
