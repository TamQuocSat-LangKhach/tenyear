local lianzhi = fk.CreateSkill {
  name = "lianzhi",
}

Fk:loadTranslationTable{
  ["lianzhi"] = "连枝",
  [":lianzhi"] = "游戏开始时，你选择一名其他角色。每回合限一次，当你进入濒死状态时，若该角色没有死亡，你回复1点体力并与其各摸一张牌。"..
  "该角色死亡时，你可以选择一名其他角色，你与其获得〖受责〗，其获得与你等量的“绞”标记（至少1个）。",

  ["@lianzhi"] = "连枝",
  ["#lianzhi-choose"] = "连枝：选择一名角色成为“连枝”角色",
  ["#lianzhi2-choose"] = "连枝：你可以选择一名角色，你与其获得技能〖受责〗",

  ["$lianzhi1"] = "刘董同气连枝，一损则俱损。",
  ["$lianzhi2"] = "妾虽女流，然亦有忠侍陛下之心。",
}

lianzhi:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if player:getMark(lianzhi.name) ~= 0 then
    local to = room:getPlayerById(player:getMark(lianzhi.name))
    room:removeTableMark(to, "@lianzhi", player.id)
  end
end)

lianzhi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lianzhi.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = lianzhi.name,
      prompt = "#lianzhi-choose",
      cancelable = false,
    })[1]
    room:addTableMark(to, "@lianzhi", {player.id})
    room:setPlayerMark(player, lianzhi.name, to.id)
  end,
})

lianzhi:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianzhi.name) and player:getMark(lianzhi.name) ~= 0 and
      not player.room:getPlayerById(player:getMark(lianzhi.name)).dead and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark(lianzhi.name))
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = lianzhi.name
    }
    if not player.dead then
      player:drawCards(1, lianzhi.name)
    end
    if not to.dead then
      to:drawCards(1, lianzhi.name)
    end
  end,
})

lianzhi:addEffect(fk.Death, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lianzhi.name) and player:getMark(lianzhi.name) == target.id and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = lianzhi.name,
      prompt = "#lianzhi2-choose",
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
    room:handleAddLoseSkills(player, "shouze")
    room:handleAddLoseSkills(to, "shouze")
    room:addPlayerMark(to, "@dongguiren_jiao", math.max(player:getMark("@dongguiren_jiao"), 1))
  end,
})

return lianzhi
