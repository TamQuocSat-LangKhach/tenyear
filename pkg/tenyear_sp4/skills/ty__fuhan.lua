local ty__fuhan = fk.CreateSkill {
  name = "ty__fuhan"
}

Fk:loadTranslationTable{
  ['ty__fuhan'] = '扶汉',
  ['#ty__fuhan-invoke'] = '扶汉：你可以移去“梅影”标记，获得两个蜀势力武将的技能！',
  ['#ty__fuhan-choice'] = '扶汉：选择你要获得的至多2个技能',
  [':ty__fuhan'] = '限定技，回合开始时，若你有“梅影”标记，你可以移去所有“梅影”标记并摸等量的牌，然后从X张（X为存活人数且至少为4）蜀势力武将牌中选择并获得至多两个技能（限定技、觉醒技、主公技除外）。若此时你是体力值最低的角色，你回复1点体力。',
  ['$ty__fuhan1'] = '汉盛刘兴，定可指日成之。',
  ['$ty__fuhan2'] = '蜀汉兴存，吾必定尽力而为。',
}

ty__fuhan:addEffect(fk.TurnStart, {
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__fuhan.name) and player:getMark("@meiying") > 0 and
      player:usedSkillTimes(ty__fuhan.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty__fuhan.name,
      prompt = "#ty__fuhan-invoke"
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    player:drawCards(n, ty__fuhan.name)
    if player.dead then return end

    local generals, same_g = {}, {}
    for _, general_name in ipairs(room.general_pile) do
      same_g = Fk:getSameGenerals(general_name)
      table.insert(same_g, general_name)
      same_g = table.filter(same_g, function (g_name)
        local general = Fk.generals[g_name]
        return general.kingdom == "shu" or general.subkingdom == "shu"
      end)
      if #same_g > 0 then
        table.insert(generals, table.random(same_g))
      end
    end
    if #generals == 0 then return false end
    generals = table.random(generals, math.max(4, #room.alive_players))

    local skills = {}
    local choices = {}
    for _, general_name in ipairs(generals) do
      local general = Fk.generals[general_name]
      local g_skills = {}
      for _, skill in ipairs(general.skills) do
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
          (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "shu") and player.kingdom == "shu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      for _, s_name in ipairs(general.other_skills) do
        local skill = Fk.skills[s_name]
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
          (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "shu") and player.kingdom == "shu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      table.insertIfNeed(skills, g_skills)
      if #choices == 0 and #g_skills > 0 then
        choices = {g_skills[1]}
      end
    end
    if #choices > 0 then
      local result = player.room:askToCustomDialog(player, {
        skill_name = ty__fuhan.name,
        qml_path = "packages/tenyear/qml/ChooseGeneralSkillsBox.qml",
        extra_data = {generals, skills, 1, 2, "#ty__fuhan-choice", false}
      })
      if result ~= "" then
        choices = json.decode(result)
      end
      room:handleAddLoseSkills(player, table.concat(choices, "|"), nil)
    end

    if not player.dead and player:isWounded() and
      table.every(room.alive_players, function(p) return p.hp >= player.hp end) then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = ty__fuhan.name
      })
    end
  end,
})

return ty__fuhan
