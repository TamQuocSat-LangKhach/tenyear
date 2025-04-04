local tongdao = fk.CreateSkill {
  name = "tongdao",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["tongdao"] = "痛悼",
  [":tongdao"] = "限定技，当你处于濒死状态时，你可以令一名角色技能还原为游戏开始时状态。若不为你，你回复体力至与其相同。",

  ["#tongdao-choose"] = "痛悼：你可以令一名角色将技能还原为初始状态，你回复体力至与其相同",

  ["$tongdao1"] = "安定宫无一丈之长，恐难七步成诗。",
  ["$tongdao2"] = "故峻恶，皓恶甚于峻。",
}

tongdao:addEffect(fk.AskForPeaches, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongdao.name) and
      data.who == player and
      player:usedSkillTimes(tongdao.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#tongdao-choose",
      skill_name = tongdao.name,
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
    local skills = to:getSkillNameList()
    if room.settings.gameMode == "m_1v2_mode" and to.role == "lord" then
      table.removeOne(skills, "m_feiyang")
      table.removeOne(skills, "m_bahu")
    end
    if #skills > 0 then
      room:handleAddLoseSkills(to, "-"..table.concat(skills, "|-"), nil, false, true)
    end
    local lord_judge = room:isGameMode("role_mode") and to.role_shown and to.role == "lord"
    skills = Fk.generals[to.general]:getSkillNameList(lord_judge)
    if to.deputyGeneral ~= "" then
      table.insertTableIfNeed(skills, Fk.generals[to.deputyGeneral]:getSkillNameList(lord_judge))
    end
    local skill
    if #skills > 0 then
      for _, skill_name in ipairs(skills) do
        skill = Fk.skills[skill_name]
        if skill:hasTag(Skill.Quest) then
          room:setPlayerMark(to, MarkEnum.QuestSkillPreName .. skill_name, 0)
        end
        if skill:hasTag(Skill.Switch) then
          room:setPlayerMark(to, MarkEnum.SwithSkillPreName .. skill_name, fk.SwitchYang)
        end
        to:setSkillUseHistory(skill_name, 0, Player.HistoryPhase)
        to:setSkillUseHistory(skill_name, 0, Player.HistoryTurn)
        to:setSkillUseHistory(skill_name, 0, Player.HistoryRound)
        to:setSkillUseHistory(skill_name, 0, Player.HistoryGame)
      end
      room:handleAddLoseSkills(to, table.concat(skills, "|"), nil, false, true)
    end
    if not (player.dead or target.dead) and player:isWounded() and player.hp < to.hp then
      room:recover {
        who = player,
        num = to.hp - player.hp,
        recoverBy = player,
        skillName = tongdao.name,
      }
    end
  end,
})

return tongdao
