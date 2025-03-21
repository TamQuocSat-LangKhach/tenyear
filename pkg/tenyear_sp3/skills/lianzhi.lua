local lianzhi = fk.CreateSkill {
  name = "lianzhi"
}

Fk:loadTranslationTable{
  ['lianzhi'] = '连枝',
  ['#lianzhi-choose'] = '连枝：选择一名角色成为“连枝”角色',
  ['#lianzhi2-choose'] = '连枝：你可以选择一名角色，你与其获得技能〖受责〗',
  ['shouze'] = '受责',
  ['@dongguiren_jiao'] = '绞',
  ['@lianzhi'] = '连枝',
  [':lianzhi'] = '游戏开始时，你选择一名其他角色。每回合限一次，当你进入濒死状态时，若该角色没有死亡，你回复1点体力且与其各摸一张牌。该角色死亡时，你可以选择一名其他角色，你与其获得〖受责〗，其获得与你等量的“绞”标记（至少1个）。',
  ['$lianzhi1'] = '刘董同气连枝，一损则俱损。',
  ['$lianzhi2'] = '妾虽女流，然亦有忠侍陛下之心。',
}

-- GameStart and Deathed events
lianzhi:addEffect({fk.GameStart, fk.Deathed}, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(lianzhi.name) then
      if event == fk.GameStart then
        return true
      else
        return player:getMark("lianzhi") == target.id
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    if event == fk.GameStart then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#lianzhi-choose",
        skill_name = lianzhi.name,
        cancelable = false,
        no_indicate = true
      })
      if #to > 0 then
        to = room:getPlayerById(to[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:setPlayerMark(player, "lianzhi", to.id)
    else
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#lianzhi2-choose",
        skill_name = lianzhi.name,
        cancelable = true
      })
      if #to > 0 then
        to = room:getPlayerById(to[1])
        room:handleAddLoseSkills(player, "shouze", nil, true, false)
        room:handleAddLoseSkills(to, "shouze", nil, true, false)
        room:addPlayerMark(to, "@dongguiren_jiao", math.max(player:getMark("@dongguiren_jiao"), 1))
      end
    end
  end,
})

-- EnterDying event for #lianzhi_trigger
lianzhi:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianzhi.name) and player:getMark("lianzhi") ~= 0 and
      not player.room:getPlayerById(player:getMark("lianzhi")).dead and player:usedSkillTimes("#lianzhi_trigger", Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(lianzhi.name)
    room:notifySkillInvoked(player, lianzhi.name, "support")
    local lianzhi_id = player:getMark("lianzhi")
    local to = room:getPlayerById(lianzhi_id)
    if player:getMark("@lianzhi") == 0 then
      room:setPlayerMark(player, "@lianzhi", to.general)
    end
    room:doIndicate(player.id, {lianzhi_id})
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = lianzhi.name
    })
    if not player.dead then
      player:drawCards(1, lianzhi.name)
    end
    if not to.dead then
      to:drawCards(1, lianzhi.name)
    end
  end,
})

return lianzhi
