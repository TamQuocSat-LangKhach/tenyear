local yaoyi = fk.CreateSkill {
  name = "yaoyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yaoyi"] = "邀弈",
  [":yaoyi"] = "锁定技，游戏开始时，所有没有转换技的角色获得〖手谈〗；你发动〖手谈〗无需弃置牌且无次数限制。所有角色使用牌只能"..
  "指定自己及与自己转换技状态不同的角色为目标。",

  ["$yaoyi1"] = "对弈未分高下，胜负可问春风。",
  ["$yaoyi2"] = "我掷三十六道，邀君游弈其中。",
}

yaoyi:addEffect(fk.GameStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yaoyi.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(player.room:getAlivePlayers()) do
      if not p.dead  then
        local yes = true
        for _, skill in ipairs(p:getSkillNameList()) do
          if Fk.skills[skill]:hasTag(Skill.Switch) then
            yes = false
            break
          end
        end
        if yes then
          room:handleAddLoseSkills(p, "shoutan")
        end
      end
    end
  end,
})

yaoyi:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if from ~= to and table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill(yaoyi.name) end) then
      local fromskill
      for _, skill in ipairs(from:getSkillNameList()) do
        if Fk.skills[skill]:hasTag(Skill.Switch) then
          if fromskill == nil then
            fromskill = from:getSwitchSkillState(skill)
          elseif fromskill ~= from:getSwitchSkillState(skill) then
            return false
          end
        end
      end
      if fromskill == nil then return false end
      local toskill
      for _, skill in ipairs(to:getSkillNameList()) do
        if Fk.skills[skill]:hasTag(Skill.Switch) then
          if toskill == nil then
            toskill = to:getSwitchSkillState(skill)
          elseif toskill ~= to:getSwitchSkillState(skill) then
            return false
          end
        end
      end
      return fromskill == toskill
    end
  end,
})

return yaoyi
