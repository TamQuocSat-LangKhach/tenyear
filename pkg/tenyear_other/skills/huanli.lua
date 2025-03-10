local huanli = fk.CreateSkill {
  name = "huanli",
}

Fk:loadTranslationTable{
  ['huanli'] = '唤理',
  ['#huanli_zhangzhao-choose'] = '唤理：你可令一名其他角色技能失效且获得“直谏”“固政”直到其下回合结束',
  ['@@huanli'] = '唤理',
  ['#huanli_zhouyu-choose'] = '唤理：你可令其中一名角色技能失效且获得“英姿”“反间”直到其下回合结束',
  ['#huanli_lose'] = '唤理',
  [':huanli'] = '结束阶段开始时，若你于本回合内使用牌指定自己为目标至少三次，你可以令一名其他角色所有技能失效（因本技能而获得的技能除外），且其获得“直谏”和“固政”直到其下回合结束。若你于本回合内使用牌指定同一名其他角色为目标至少三次，你可选择这些角色中的一名（不能选择前者选择的角色），令其所有技能失效（因本技能而获得的技能除外），且其获得“英姿”和“反间”直到其下回合结束。若你两项均执行，则你获得“制衡”直到你下回合结束。',
  ['$huanli1'] = '金乌当空，汝欲与我辩日否？',
  ['$huanli2'] = '童言无忌，童言有理！',
}

huanli:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    if not (target == player and player:hasSkill(huanli.name) and player.phase == Player.Finish) then
      return false
    end

    local aimedList = {}
    local canTrigger = false
    player.room.logic:getEventsOfScope(
      GameEvent.UseCard,
      1,
      function(e)
        local targets = TargetGroup:getRealTargets(e.data[1].tos)
        for _, pId in ipairs(targets) do
          aimedList[pId] = (aimedList[pId] or 0) + 1
          canTrigger = canTrigger or aimedList[pId] > 2
        end
        return false
      end,
      Player.HistoryTurn
    )

    if canTrigger then
      event:setCostData(self, aimedList)
      return true
    end

    return false
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    local aimedList = event:getCostData(self)
    local usedTimes = 0
    local lastTarget
    if (aimedList[player.id] or 0) > 2 then
      local tos = room:askToChoosePlayers(
        player,
        {
          targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
          min_num = 1,
          max_num = 1,
          prompt = "#huanli_zhangzhao-choose",
          skill_name = huanli.name
        }
      )

      if #tos > 0 then
        usedTimes = usedTimes + 1
        lastTarget = tos[1]

        local to = room:getPlayerById(tos[1])
        local zhangzhao = table.filter({ "zhijian", "guzheng" }, function(skill) return not to:hasSkill(skill, true, true) end)
        local skillsExist = to:getTableMark("@@huanli")
        table.insertTableIfNeed(skillsExist, zhangzhao)
        room:setPlayerMark(to, "@@huanli", skillsExist)

        if #zhangzhao > 0 then
          room:handleAddLoseSkills(to, table.concat(zhangzhao, "|"))
        end
      end
    end

    local availableTargets = {}
    for pId, num in pairs(aimedList) do
      if pId ~= player.id and pId ~= lastTarget and num > 2 then
        table.insert(availableTargets, pId)
      end
    end

    if #availableTargets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        prompt = "#huanli_zhouyu-choose",
        skill_name = huanli.name
      }
    )
    if #tos > 0 then
      usedTimes = usedTimes + 1
      local to = room:getPlayerById(tos[1])
      local zhouyu = table.filter({ "ex__yingzi", "ex__fanjian" }, function(skill) return not to:hasSkill(skill, true, true) end)
      local skillsExist = to:getTableMark("@@huanli")
      table.insertTableIfNeed(skillsExist, zhouyu)
      room:setPlayerMark(to, "@@huanli", skillsExist)

      if #zhouyu > 0 then
        room:handleAddLoseSkills(to, table.concat(zhouyu, "|"))
      end
    end

    if usedTimes > 1 and not player:hasSkill("ex__zhiheng") then
      room:setPlayerMark(player, "huanli_sunquan-turn", 1)
      player.tag["huanli_sunquan"] = true
      room:handleAddLoseSkills(player, "ex__zhiheng")
    end
  end,
})

huanli:addEffect(fk.TurnEnd, {
  name = "#huanli_lose",
  mute = true,
  can_trigger = function(self, event, target, player)
    return
      target == player and
      (
      player:getMark("@@huanli") ~= 0 or
      (player:getMark("huanli_sunquan-turn") == 0 and player.tag["huanli_sunquan"])
    )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    if player:getMark("@@huanli") ~= 0 then
      local huanliSkills = table.simpleClone(player:getTableMark("@@huanli"))
      room:setPlayerMark(player, "@@huanli", 0)
      if #huanliSkills > 0 then
        room:handleAddLoseSkills(player, table.concat(table.map(huanliSkills, function(skill) return "-" .. skill end), "|"))
      end
    end

    if player:getMark("huanli_sunquan-turn") == 0 and player.tag["huanli_sunquan"] then
      player.tag["huanli_sunquan"] = nil
      room:handleAddLoseSkills(player, "-ex__zhiheng")
    end
  end,
})

huanli:addEffect("invalidity", {
  name = "#huanli_nullify",
  invalidity_func = function(self, from, skill)
    return
      from:getMark("@@huanli") ~= 0 and
      not table.contains(from:getTableMark("@@huanli"), skill.name) and
      skill:isPlayerSkill(from)
  end,
})

return huanli
