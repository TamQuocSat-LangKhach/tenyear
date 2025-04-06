local ligong = fk.CreateSkill {
  name = "ligong",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ligong"] = "离宫",
  [":ligong"] = "觉醒技，准备阶段，若〖慧淑〗有数字达到5，你加1点体力上限并回复1点体力，失去〖易数〗，然后从随机四个吴国女性武将中"..
  "选择至多两个技能获得并失去〖慧淑〗（如果不获得技能则改为摸三张牌）。",

  ["#ligong-choice"] = "离宫：选择至多2个武将技能",

  ["$ligong1"] = "伴君离高墙，日暮江湖远。",
  ["$ligong2"] = "巍巍宫门开，自此不复来。",
}

ligong:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ligong.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(ligong.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:hasSkill("huishu", true) and
      (player:getMark("huishu1") > 1 or player:getMark("huishu2") > 3 or player:getMark("huishu3") > 2)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = ligong.name,
      }
      if player.dead then return end
    end
    room:handleAddLoseSkills(player, "-yishu")
    if player.dead then return end

    local generals, same_g = {}, {}
    for _, general_name in ipairs(room.general_pile) do
      same_g = Fk:getSameGenerals(general_name)
      table.insert(same_g, general_name)
      same_g = table.filter(same_g, function (g_name)
        local general = Fk.generals[g_name]
        return (general.kingdom == "wu" or general.subkingdom == "wu") and general.gender == General.Female
      end)
      if #same_g > 0 then
        table.insert(generals, table.random(same_g))
      end
    end
    if #generals == 0 then return false end
    generals = table.random(generals, 4)

    local skills = {}
    for _, general_name in ipairs(generals) do
      local g_skills = {}
      for _, s in ipairs(Fk.generals[general_name]:getSkillNameList()) do
        local skill = Fk.skills[s]
        if not table.find({Skill.Limited, Skill.Wake, Skill.Quest}, function (tag)
          return skill:hasTag(tag)
        end) then
          if skill:hasTag(Skill.AttachedKingdom) then
            if table.contains(skill:getSkeleton().attached_kingdom, "wu") and player.kingdom == "wu" then
              table.insertIfNeed(g_skills, skill.name)
            end
          else
            table.insertIfNeed(g_skills, skill.name)
          end
        end
      end
      table.insertIfNeed(skills, g_skills)
    end

    local result = room:askToCustomDialog(player, {
      skill_name = ligong.name,
      qml_path = "packages/tenyear/qml/ChooseGeneralSkillsBox.qml",
      extra_data = {generals, skills, 1, 2, "#ligong-choice", true}
    })

    local choices = {}
    if result ~= "" then
      choices = json.decode(result)
    end

    if #choices == 0 then
      player:drawCards(3, ligong.name)
    else
      room:handleAddLoseSkills(player, "-huishu|"..table.concat(choices, "|"))
    end
  end,
})

return ligong
