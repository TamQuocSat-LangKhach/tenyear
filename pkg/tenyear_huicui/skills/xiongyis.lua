local xiongyis = fk.CreateSkill {
  name = "xiongyis",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xiongyis"] = "凶疑",
  [":xiongyis"] = "限定技，当你处于濒死状态时，若徐氏：不在场，你可以将体力值回复至3点并将武将牌替换为徐氏；在场，你可以将体力值回复至1点"..
  "并获得技能〖魂姿〗。",

  ["#xiongyis1-invoke"] = "凶疑：你可以将回复体力至%arg点并变身为徐氏！",
  ["#xiongyis2-invoke"] = "凶疑：你可以将回复体力至1点并获得“魂姿”！",

  ["$xiongyis1"] = "此仇不报，吾恨难消！",
  ["$xiongyis2"] = "功业未立，汝可继之！",
}

xiongyis:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiongyis.name) and player.dying and
      player:usedSkillTimes(xiongyis.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#xiongyis1-invoke:::"..math.min(3, player.maxHp)
    if table.find(player.room.alive_players, function(p)
      return Fk.generals[p.general].trueName == "xushi"
        or (Fk.generals[p.deputyGeneral] and Fk.generals[p.deputyGeneral].trueName == "xushi")
      end) then
      prompt = "#xiongyis2-invoke"
    end
    if player.room:askToSkillInvoke(player, {
      skill_name = xiongyis.name,
      prompt = prompt,
    }) then
      event:setCostData(self, {choice = prompt})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice:startsWith("#xiongyis1") then
      room:recover{
        who = player,
        num = math.min(3, player.maxHp) - player.hp,
        recoverBy = player,
        skillName = xiongyis.name,
      }
      local isDeputy = false
      if player.deputyGeneral ~= "" and table.contains(Fk.generals[player.deputyGeneral]:getSkillNameList(), xiongyis.name) then
        isDeputy = true
      end
      if table.contains(Fk.generals[player.general]:getSkillNameList(), xiongyis.name) then
        isDeputy = false
      end
      room:changeHero(player, "xushi", false, isDeputy, true)
    else
      room:recover{
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = xiongyis.name
      }
      room:handleAddLoseSkills(player, "hunzi")
    end
  end,
})

return xiongyis
