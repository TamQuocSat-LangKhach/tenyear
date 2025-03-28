local yizheng = fk.CreateSkill {
  name = "yizhengc",
}

Fk:loadTranslationTable{
  ["yizhengc"] = "翊正",
  [":yizhengc"] = "结束阶段，你可以选择一名其他角色。直到你的下回合开始，当该角色造成伤害或回复体力时，若其体力上限小于你，你减1点体力上限，"..
  "然后此伤害或回复值+1。",

  ["@@yizhengc"] = "翊正",
  ["#yizhengc-choose"] = "翊正：你可以指定一名角色，直到你下回合开始，其造成伤害/回复体力时数值+1，你减1点体力上限",

  ["$yizhengc1"] = "玉树盈阶，望子成龙！",
  ["$yizhengc2"] = "择善者，翊赞季兴。",
}

yizheng:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if player:getMark(yizheng.name) ~= 0 then
    local to = room:getPlayerById(player:getMark(yizheng.name))
    room:removeTableMark(to, "@@yizhengc", player.id)
  end
end)

yizheng:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yizheng.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#yizhengc-choose",
      skill_name = yizheng.name,
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
    room:addTableMarkIfNeed(to, "@@yizhengc", player.id)
    room:setPlayerMark(player, yizheng.name, to.id)
  end
})

yizheng:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target and player:getMark(yizheng.name) == target.id and player.maxHp > target.maxHp
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:changeMaxHp(player, -1)
    data:changeDamage(1)
  end
})

yizheng:addEffect(fk.PreHpRecover, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark(yizheng.name) == target.id and player.maxHp > target.maxHp
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:changeMaxHp(player, -1)
    data:changeRecover(1)
  end
})

yizheng:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(yizheng.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark(yizheng.name))
    room:setPlayerMark(player, yizheng.name, 0)
    room:removeTableMark(to, "@@yizhengc", player.id)
  end
})

return yizheng
