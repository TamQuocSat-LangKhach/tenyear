local fuhan = fk.CreateSkill {
  name = "ty__fuhan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ty__fuhan"] = "扶汉",
  [":ty__fuhan"] = "限定技，回合开始时，若你有“梅影”标记，你可以移去所有“梅影”标记并摸等量的牌，然后从X张（X为存活人数且至少为4）"..
  "蜀势力武将牌中选择并获得至多两个技能（限定技、觉醒技、主公技除外）。若此时你是体力值最低的角色，你回复1点体力。",

  ["#ty__fuhan-invoke"] = "扶汉：你可以移去“梅影”标记，获得两个蜀势力武将的技能！",
  ["#ty__fuhan-choice"] = "扶汉：选择你要获得的至多2个技能",

  ["$ty__fuhan1"] = "汉盛刘兴，定可指日成之。",
  ["$ty__fuhan2"] = "蜀汉兴存，吾必定尽力而为。",
}

fuhan:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuhan.name) and
      player:getMark("@meiying") > 0 and
      player:usedSkillTimes(fuhan.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = fuhan.name,
      prompt = "#ty__fuhan-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    player:drawCards(n, fuhan.name)
    if player.dead then return end

    local generals, same_generals = {}, {}
    for _, general_name in ipairs(room.general_pile) do
      same_generals = Fk:getSameGenerals(general_name)
      table.insert(same_generals, general_name)
      same_generals = table.filter(same_generals, function (g_name)
        local general = Fk.generals[g_name]
        return general.kingdom == "shu" or general.subkingdom == "shu"
      end)
      if #same_generals > 0 then
        table.insert(generals, table.random(same_generals))
      end
    end
    if #generals == 0 then return false end
    generals = table.random(generals, math.max(4, #room.alive_players))

    local skills = {}
    for _, general_name in ipairs(generals) do
      local general = Fk.generals[general_name]
      local general_skills = {}
      for _, s in ipairs(general:getSkillNameList()) do
        local skill = Fk.skills[s]
        if not table.find({Skill.Limited, Skill.Wake, Skill.Quest, Skill.Lord}, function (tag)
          return skill:hasTag(tag)
        end) and
        not (skill:hasTag(Skill.AttachedKingdom) and not table.contains(skill:getSkeleton().attached_kingdom, player.kingdom)) then
          table.insertIfNeed(general_skills, s)
        end
      end
      table.insertIfNeed(skills, general_skills)
    end
    if #skills > 0 then
      local result = player.room:askToCustomDialog(player, {
        skill_name = fuhan.name,
        qml_path = "packages/tenyear/qml/ChooseGeneralSkillsBox.qml",
        extra_data = {generals, skills, 1, 2, "#ty__fuhan-choice", false}
      })
      local choices = result ~= "" and json.decode(result) or table.random(skills, 2)
      room:handleAddLoseSkills(player, table.concat(choices, "|"))
    end

    if not player.dead and player:isWounded() and
      table.every(room.alive_players, function(p)
        return p.hp >= player.hp
      end) then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = fuhan.name,
      }
    end
  end,
})

return fuhan
