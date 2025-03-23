local huaping = fk.CreateSkill {
  name = "huaping"
}

Fk:loadTranslationTable{
  ['huaping'] = '化萍',
  ['#huaping-choose'] = '化萍：选择一名角色，令其获得沙舞',
  ['#huaping-invoke'] = '化萍：你可以获得%dest的所有武将技能，然后失去绡舞',
  ['shawu'] = '沙舞',
  ['@xiaowu_sand'] = '沙',
  [':huaping'] = '限定技，一名其他角色死亡时，你可以获得其所有武将技能，然后你失去〖绡舞〗和所有“沙”标记并摸等量的牌。你死亡时，你可以令一名其他角色获得技能〖沙舞〗和所有“沙”标记。',
  ['$huaping1'] = '风絮飘残，化萍而终。',
  ['$huaping2'] = '莲泥刚倩，藕丝萦绕。',
}

huaping:addEffect(fk.Death, {
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(huaping.name, false, player == target) and player:usedSkillTimes(huaping.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player == target then
      local to = player.room:askToChoosePlayers(player, {
        targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#huaping-choose",
        skill_name = huaping.name,
        cancelable = true
      })
      if #to > 0 then
        event:setCostData(self, to[1])
        return true
      end
    else
      return player.room:askToSkillInvoke(player, {
        skill_name = huaping.name,
        prompt = "#huaping-invoke::"..target.id
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player == target then
      local to = room:getPlayerById(event:getCostData(self))
      room:handleAddLoseSkills(to, "shawu", nil, true, false)
      room:setPlayerMark(to, "@xiaowu_sand", player:getMark("@xiaowu_sand"))
    else
      local skills = {}
      for _, s in ipairs(target.player_skills) do
        if s:isPlayerSkill(target) then
          table.insertIfNeed(skills, s.name)
        end
      end
      if #skills > 0 then
        room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
      end
      local x = player:getMark("@xiaowu_sand")
      room:handleAddLoseSkills(player, "-xiaowu", nil, true, false)
      room:setPlayerMark(player, "@xiaowu_sand", 0)
      if x > 0 then
        player:drawCards(x, huaping.name)
      end
    end
  end,
})

return huaping
