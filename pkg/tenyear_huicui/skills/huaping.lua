local huaping = fk.CreateSkill {
  name = "huaping",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["huaping"] = "化萍",
  [":huaping"] = "限定技，一名其他角色死亡时，你可以获得其所有技能，然后你失去〖绡舞〗和所有“沙”标记并摸等量的牌。当你死亡时，"..
  "你可以令一名其他角色获得技能〖沙舞〗和所有“沙”标记。",

  ["#huaping-invoke"] = "化萍：是否获得 %dest 的所有技能，然后失去“绡舞”？",
  ["#huaping-choose"] = "化萍：你可以令一名角色获得“沙舞”",

  ["$huaping1"] = "风絮飘残，化萍而终。",
  ["$huaping2"] = "莲泥刚倩，藕丝萦绕。",
}

huaping:addEffect(fk.Death, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes(huaping.name, Player.HistoryGame) == 0 then
      if target == player then
        return player:hasSkill(huaping.name, false, true) and #player.room:getOtherPlayers(player, false) > 0
      else
        return player:hasSkill(huaping.name)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player == target then
      local to = room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#huaping-choose",
        skill_name = huaping.name,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    elseif room:askToSkillInvoke(player, {
        skill_name = huaping.name,
        prompt = "#huaping-invoke::"..target.id,
      }) then
        event:setCostData(self, {tos = {target}})
        return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player == target then
      local to = event:getCostData(self).tos[1]
      room:handleAddLoseSkills(to, "shawu")
      room:setPlayerMark(to, "@xiaowu_sand", player:getMark("@xiaowu_sand"))
    else
      local skills = table.filter(target:getSkillNameList(), function (s)
        if not player:hasSkill(s, true) then
          local skill = Fk.skills[s]
          if skill:hasTag(Skill.AttachedKingdom) then
            return table.contains(skill:getSkeleton().attached_kingdom, player.kingdom)
          else
            return true
          end
        end
      end)
      if #skills > 0 then
        room:handleAddLoseSkills(player, table.concat(skills, "|"))
        if player.dead then return end
      end
      local x = player:getMark("@xiaowu_sand")
      room:handleAddLoseSkills(player, "-xiaowu")
      room:setPlayerMark(player, "@xiaowu_sand", 0)
      if x > 0 then
        player:drawCards(x, huaping.name)
      end
    end
  end,
})

return huaping
