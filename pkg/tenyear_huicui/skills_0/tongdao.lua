local tongdao = fk.CreateSkill {
  name = "tongdao"
}

Fk:loadTranslationTable{
  ['tongdao'] = '痛悼',
  ['#tongdao-choose'] = '是否发动 痛悼，选择一名角色，令其技能还原为初始状态，并回复体力至与该角色相同',
  [':tongdao'] = '限定技，当你处于濒死状态时，你可以选择一名角色，其失去所有技能，其获得其武将牌上的所有技能，你回复体力至X点（X为其体力值）。',
  ['$tongdao1'] = '安定宫无一丈之长，恐难七步成诗。',
  ['$tongdao2'] = '故峻恶，皓恶甚于峻。',
}

tongdao:addEffect(fk.AskForPeaches, {
  anim_type = "support",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(tongdao.name) and
      data.who == player.id and
      player:usedSkillTimes(tongdao.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#tongdao-choose",
      skill_name = tongdao.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(skill, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill).tos[1])
    local skills = {}
    for _, s in ipairs(to.player_skills) do
      if s:isPlayerSkill(to) then
        table.insertIfNeed(skills, s.name)
      end
    end
    if room.settings.gameMode == "m_1v2_mode" and to.role == "lord" then
      table.removeOne(skills, "m_feiyang")
      table.removeOne(skills, "m_bahu")
    end
    if #skills > 0 then
      room:handleAddLoseSkills(to, "-"..table.concat(skills, "|-"), nil, true, false)
    end
    skills = Fk.generals[to.general]:getSkillNameList(true)
    if to.deputyGeneral ~= "" then
      table.insertTableIfNeed(skills, Fk.generals[to.deputyGeneral]:getSkillNameList(true))
    end
    local skill
    if not (room:isGameMode("role_mode") and
      to.role_shown and to.role == "lord") then
      skills = table.filter(skills, function(skill_name)
        skill = Fk.skills[skill_name]
        return not skill.lordSkill
      end)
    end
    if #skills > 0 then
      for _, skill_name in ipairs(skills) do
        skill = Fk.skills[skill_name]
        if skill.frequency == Skill.Quest then
          room:setPlayerMark(to, MarkEnum.QuestSkillPreName .. skill_name, 0)
        end
        if skill.switchSkillName then
          room:setPlayerMark(to, MarkEnum.SwithSkillPreName .. skill_name, fk.SwitchYang)
        end
        to:setSkillUseHistory(skill_name, 0, Player.HistoryPhase)
        to:setSkillUseHistory(skill_name, 0, Player.HistoryTurn)
        to:setSkillUseHistory(skill_name, 0, Player.HistoryRound)
        to:setSkillUseHistory(skill_name, 0, Player.HistoryGame)
      end
      room:handleAddLoseSkills(to, table.concat(skills, "|"), nil, true, false)
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
