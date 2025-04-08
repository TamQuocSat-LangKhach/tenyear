local jiezhen = fk.CreateSkill {
  name = "jiezhen",
}

Fk:loadTranslationTable{
  ["jiezhen"] = "解阵",
  [":jiezhen"] = "出牌阶段限一次，你可以令一名其他角色所有技能替换为〖八阵〗（锁定技、限定技、觉醒技、主公技除外）。你的回合开始时或"..
  "当其【八卦阵】判定后，其失去〖八阵〗并获得原技能，然后你获得其区域里的一张牌。",

  ["#jiezhen"] = "解阵：将一名角色的技能替换为〖八阵〗",
  ["@@jiezhen"] = "解阵",

  ["$jiezhen1"] = "八阵无破，唯解死而向生。",
  ["$jiezhen2"] = "此阵，可由景门入、生门出。",
}

jiezhen:addEffect("active", {
  anim_type = "control",
  prompt = "#jiezhen",
  can_use = function(self, player)
    return player:usedSkillTimes(jiezhen.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:getMark("@@jiezhen") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local skills = {}
    for _, s in ipairs(target:getSkillNameList()) do
      local skill = Fk.skill_skels[s]
      if not table.find({Skill.Compulsory, Skill.Limited, Skill.Wake, Skill.Lord}, function (tag)
        return table.contains(skill.tags, tag)
      end) then
        table.insert(skills, s)
      end
    end
    room:setPlayerMark(target, "@@jiezhen", skills)
    if #skills > 0 then
      room:handleAddLoseSkills(target, "-"..table.concat(skills, "|-"))
    end
    room:setPlayerMark(target, "jiezhen_source", player.id)
    if not target:hasSkill("bazhen", true) then
      room:setPlayerMark(target, "jiezhen-tmp", 1)
      room:handleAddLoseSkills(target, "bazhen")
    end
  end,
})

jiezhen:addEffect(fk.FinishJudge, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiezhen.name) and not target.dead and
      data.reason == "eight_diagram" and
      target:getMark("jiezhen_source") == player.id
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "jiezhen_source", 0)
    local skills = target:getMark("@@jiezhen")
    room:setPlayerMark(target, "@@jiezhen", 0)
    if #skills > 0 then
      room:handleAddLoseSkills(target, table.concat(skills, "|"))
    end
    if target:getMark("jiezhen-tmp") > 0 then
      room:setPlayerMark(target, "jiezhen-tmp", 0)
      room:handleAddLoseSkills(target, "-bazhen")
    end
    if not target:isAllNude() then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "hej",
        skill_name = jiezhen.name,
      })
      room:obtainCard(player, card, false, fk.ReasonPrey, player, jiezhen.name)
    end
  end,
})

jiezhen:addEffect(fk.TurnStart, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiezhen.name) and
      table.find(player.room.alive_players, function (p)
        return p:getMark("jiezhen_source") == player.id
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local tos = table.filter(player.room:getAlivePlayers(), function (p)
      return p:getMark("jiezhen_source") == player.id
    end)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local tos = table.filter(room:getAlivePlayers(), function (p)
      return p:getMark("jiezhen_source") == player.id
    end)
    for _, to in ipairs(tos) do
      if player.dead then break end
      room:setPlayerMark(to, "jiezhen_source", 0)
      local skills = to:getMark("@@jiezhen")
      room:setPlayerMark(to, "@@jiezhen", 0)
      if #skills > 0 then
        room:handleAddLoseSkills(to, table.concat(skills, "|"))
      end
      if to:getMark("jiezhen-tmp") > 0 then
        room:setPlayerMark(to, "jiezhen-tmp", 0)
        room:handleAddLoseSkills(to, "-bazhen")
      end
      if not to:isAllNude() then
        local card = room:askToChooseCard(player, {
          target = to,
          flag = "hej",
          skill_name = jiezhen.name,
        })
        room:obtainCard(player, card, false, fk.ReasonPrey, player, jiezhen.name)
      end
    end
  end,
})

return jiezhen
