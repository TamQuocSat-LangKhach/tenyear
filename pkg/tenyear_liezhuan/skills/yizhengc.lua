local yizhengc = fk.CreateSkill {
  name = "yizhengc"
}

Fk:loadTranslationTable{
  ['yizhengc'] = '翊正',
  ['@@yizhengc'] = '翊正',
  ['#yizhengc-choose'] = '翊正：你可以指定一名角色，直到你下回合开始，其造成伤害/回复体力时数值+1，你减1点体力上限',
  [':yizhengc'] = '结束阶段，你可以选择一名其他角色。直到你的下回合开始，当该角色造成伤害或回复体力时，若其体力上限小于你，你减1点体力上限，然后此伤害或回复值+1。',
  ['$yizhengc1'] = '玉树盈阶，望子成龙！',
  ['$yizhengc2'] = '择善者，翊赞季兴。',
}

yizhengc:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yizhengc.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#yizhengc-choose",
      skill_name = yizhengc.name,
      cancelable = true
    })
    if #to > 0 then
      return to[1]
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(yizhengc.name)
    room:notifySkillInvoked(player, yizhengc.name, "support")
    local to = room:getPlayerById(event:getCostData(skill))
    local mark = to:getMark("@@yizhengc") or {}
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(to, "@@yizhengc", mark)
    room:setPlayerMark(player, yizhengc.name, to.id)
  end
})

yizhengc:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@@yizhengc") ~= 0 then
      for _, id in ipairs(player:getMark("@@yizhengc")) do
        local p = player.room:getPlayerById(id)
        if not p.dead and p.maxHp > player.maxHp then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, id in ipairs(player:getMark("@@yizhengc")) do
      local p = player.room:getPlayerById(id)
      p:broadcastSkillInvoke(yizhengc.name)
      player.room:notifySkillInvoked(p, yizhengc.name, "support")
      player.room:changeMaxHp(p, -1)
      data.damage = data.damage + 1
    end
  end
})

yizhengc:addEffect(fk.PreHpRecover, {
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@@yizhengc") ~= 0 then
      for _, id in ipairs(player:getMark("@@yizhengc")) do
        local p = player.room:getPlayerById(id)
        if not p.dead and p.maxHp > player.maxHp then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, id in ipairs(player:getMark("@@yizhengc")) do
      local p = player.room:getPlayerById(id)
      p:broadcastSkillInvoke(yizhengc.name)
      player.room:notifySkillInvoked(p, yizhengc.name, "support")
      player.room:changeMaxHp(p, -1)
      data.num = data.num + 1
    end
  end
})

yizhengc:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(yizhengc.name) ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark(yizhengc.name))
    room:setPlayerMark(player, yizhengc.name, 0)
    if not to.dead then
      local mark = to:getMark("@@yizhengc")
      table.removeOne(mark, player.id)
      if #mark == 0 then mark = 0 end
      room:setPlayerMark(to, "@@yizhengc", mark)
    end
  end
})

return yizhengc
