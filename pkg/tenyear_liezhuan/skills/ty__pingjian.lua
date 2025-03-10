local ty__pingjian = fk.CreateSkill {
  name = "ty__pingjian"
}

Fk:loadTranslationTable{
  ['ty__pingjian'] = '评荐',
  ['#ty__pingjian-active'] = '发动 评荐，从三个出牌阶段的技能中选择一个学习',
  ['#ty__pingjian-choice'] = '评荐：选择要学习的技能',
  ['#ty__pingjian_trigger'] = '评荐',
  [':ty__pingjian'] = '出牌阶段，或结束阶段，或当你受到伤害后，你可以从对应时机的技能池中随机抽取三个技能，然后你选择并视为拥有其中一个技能直到时机结束（每个技能限发动一次）。',
  ['$ty__pingjian1'] = '识人读心，评荐推达。',
  ['$ty__pingjian2'] = '月旦雅评，试论天下。',
}

ty__pingjian:addEffect('active', {
  name = "ty__pingjian",
  prompt = "#ty__pingjian-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("ty__pingjian_used-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "ty__pingjian_used-phase", 1)
    local skills = getPingjianSkills(player, "play")
    if #skills == 0 then return false end
    local choices = table.random(skills, 3)
    local skill_name = room:askToChoice(player, {
      choices = choices,
      skill_name = ty__pingjian.name,
      prompt = "#ty__pingjian-choice",
      detailed = true,
    })
    room:addTableMark(player, "ty__pingjian_used_skills", skill_name)
    local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase)
    if phase_event ~= nil then
      addTYPingjianSkill(player, skill_name)
      phase_event:addCleaner(function()
        removeTYPingjianSkill(player, skill_name)
      end)
    end
  end,
})

ty__pingjian:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(ty__pingjian) or player ~= target then return false end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ty__pingjian.name)
    player:broadcastSkillInvoke(ty__pingjian.name)
    local skills = getPingjianSkills(player, event)
    if #skills == 0 then return false end
    local choices = table.random(skills, 3)
    local skill_name = room:askToChoice(player, {
      choices = choices,
      skill_name = ty__pingjian.name,
      prompt = "#ty__pingjian-choice",
      detailed = true,
    })
    room:addTableMark(player, "ty__pingjian_used_skills", skill_name)
    local skill = Fk.skills[skill_name]
    if skill == nil then return false end

    addTYPingjianSkill(player, skill_name)
    if skill:triggerable(event, target, player, data) then
      skill:trigger(event, target, player, data)
    end
    removeTYPingjianSkill(player, skill_name)
  end,
})

ty__pingjian:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(ty__pingjian) or player ~= target then return false end
    return player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ty__pingjiang.name)
    player:broadcastSkillInvoke(ty__pingjian.name)
    local skills = getPingjianSkills(player, event)
    if #skills == 0 then return false end
    local choices = table.random(skills, 3)
    local skill_name = room:askToChoice(player, {
      choices = choices,
      skill_name = ty__pingjian.name,
      prompt = "#ty__pingjian-choice",
      detailed = true,
    })
    room:addTableMark(player, "ty__pingjian_used_skills", skill_name)
    local skill = Fk.skills[skill_name]
    if skill == nil then return false end

    addTYPingjianSkill(player, skill_name)
    if skill:triggerable(event, target, player, data) then
      skill:trigger(event, target, player, data)
    end
    removeTYPingjianSkill(player, skill_name)
  end,
})

ty__pingjian:addEffect('invalidity', {
  name = "#ty__pingjian_invalidity",
  invalidity_func = function(self, player, skill)
    local pingjian_skill_times = player:getTableMark("ty__pingjian_skill_times")
    return table.find(pingjian_skill_times, function (pingjian_record)
      if #pingjian_record == 2 then
        local skill_name = pingjian_record[1]
        if skill.name == skill_name or not table.every(skill.related_skills, function (s)
          return s.name ~= skill_name end) then
          return player:usedSkillTimes(skill_name) > pingjian_record[2]
        end
      end
    end)
  end
})

return ty__pingjian
