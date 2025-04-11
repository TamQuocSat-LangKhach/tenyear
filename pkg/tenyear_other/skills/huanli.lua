local huanli = fk.CreateSkill {
  name = "huanli",
}

Fk:loadTranslationTable{
  ["huanli"] = "唤理",
  [":huanli"] = "结束阶段，若你本回合内使用牌指定自己为目标至少三次，你可以令一名其他角色所有技能失效，其获得〖直谏〗和〖固政〗"..
  "直到其下回合结束。若你本回合内使用牌指定同一名其他角色为目标至少三次，你可以令其所有技能失效，其获得〖英姿〗和〖反间〗直到其下回合结束。"..
  "若两项均执行，你获得〖制衡〗直到你下回合结束。",

  ["@@huanli"] = "唤理",
  ["#huanli_zhangzhao-choose"] = "唤理：你可以令一名其他角色技能失效，其获得“直谏”“固政”直到其下回合结束",
  ["#huanli_zhouyu-choose"] = "唤理：你可以令其中一名角色技能失效，其获得“英姿”“反间”直到其下回合结束",

  ["$huanli1"] = "金乌当空，汝欲与我辩日否？",
  ["$huanli2"] = "童言无忌，童言有理！",
}

huanli:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(huanli.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 0 then
      local tos = {}
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        if use.from == player then
          for _, p in ipairs(use.tos) do
            if not p.dead then
              tos[p] = (tos[p] or 0) + 1
            end
          end
        end
        end,
        Player.HistoryTurn)
      local targets = {}
      for p, num in pairs(tos) do
        if num >= 3 then
          table.insert(targets, p)
        end
      end
      if #targets > 0 then
        event:setCostData(self, {extra_data = targets})
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(event:getCostData(self).extra_data)
    if table.removeOne(targets, player) then
      local zhangzhao = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(player, false),
        skill_name = huanli.name,
        prompt = "#huanli_zhangzhao-choose",
        cancelable = true,
      })
      if #zhangzhao > 0 then
        table.removeOne(targets, zhangzhao[1])
        event:setCostData(self, {tos = zhangzhao, choice = "zhangzhao", extra_data = targets})
        return true
      end
    else
      local zhouyu = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = huanli.name,
        prompt = "#huanli_zhouyu-choose",
        cancelable = true,
      })
      if #zhouyu > 0 then
        event:setCostData(self, {tos = zhouyu, choice = "zhouyu", extra_data = targets})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    local targets = event:getCostData(self).extra_data
    local zhangzhao, zhouyu
    if choice == "zhangzhao" then
      zhangzhao = to
      local skills = table.filter({ "zhijian", "guzheng" }, function(skill)
        return not zhangzhao:hasSkill(skill, true)
      end)
      local skillsExist = zhangzhao:getTableMark("@@huanli")
      table.insertTableIfNeed(skillsExist, skills)
      room:setPlayerMark(zhangzhao, "@@huanli", skillsExist)
      if #skills > 0 then
        room:handleAddLoseSkills(zhangzhao, table.concat(skills, "|"))
      end
      if #targets> 0 then
        to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = huanli.name,
          prompt = "#huanli_zhouyu-choose",
          cancelable = true,
        })
        if #to > 0 then
          zhouyu = to[1]
        end
      end
    else
      zhouyu = to
    end
    if zhouyu then
      local skills = table.filter({ "ex__yingzi", "ex__fanjian" }, function(skill)
        return not zhouyu:hasSkill(skill, true)
      end)
      local skillsExist = zhouyu:getTableMark("@@huanli")
      table.insertTableIfNeed(skillsExist, skills)
      room:setPlayerMark(zhouyu, "@@huanli", skillsExist)
      if #skills > 0 then
        room:handleAddLoseSkills(zhouyu, table.concat(skills, "|"))
      end
    end

    if zhangzhao and zhouyu then
      room:setPlayerMark(player, "huanli_sunquan-turn", 1)
      room:setPlayerMark(player, "huanli_sunquan", 1)
      room:handleAddLoseSkills(player, "ex__zhiheng")
    end
  end,
})

huanli:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if player:getMark("@@huanli") ~= 0 then
      elseif player:getMark("huanli_sunquan") > 0 then
        return player:getMark("huanli_sunquan-turn") == 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@huanli") ~= 0 then
      local skills = table.simpleClone(player:getTableMark("@@huanli"))
      room:setPlayerMark(player, "@@huanli", 0)
      room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
    end

    if player:getMark("huanli_sunquan") > 0 and player:getMark("huanli_sunquan-turn") == 0 then
      room:setPlayerMark(player, "huanli_sunquan", 0)
      room:handleAddLoseSkills(player, "-ex__zhiheng")
    end
  end,
})

huanli:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("@@huanli") ~= 0 and skill:isPlayerSkill(from) and
      not table.contains(from:getTableMark("@@huanli"), skill:getSkeleton().name)
  end,
})

return huanli
