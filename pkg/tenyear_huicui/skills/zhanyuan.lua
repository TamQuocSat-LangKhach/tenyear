local zhanyuan = fk.CreateSkill {
  name = "zhanyuan",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["zhanyuan"] = "战缘",
  [":zhanyuan"] = "觉醒技，准备阶段，若你发动〖蛮嗣〗获得不少于七张牌，你加1点体力上限并回复1点体力。然后你可以选择一名男性角色，"..
  "你与其获得技能〖系力〗，你失去技能〖蛮嗣〗。",

  ["#zhanyuan-choose"] = "战缘：你可以失去“蛮嗣”，与一名男性角色获得“系力”",

  ["$zhanyuan1"] = "战中结缘，虽苦亦甜。",
  ["$zhanyuan2"] = "势不同，情相随。",
}

zhanyuan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhanyuan.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(zhanyuan.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@mansi") > 6
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
        skillName = zhanyuan.name,
      }
      if player.dead then return end
    end
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:isMale()
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#zhanyuan-choose",
      skill_name = zhanyuan.name,
      cancelable = true,
    })
    if #to > 0 then
      room:handleAddLoseSkills(player, "xili|-mansi")
      room:handleAddLoseSkills(to[1], "xili")
    end
  end,
})

zhanyuan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@mansi", 0)
end)

return zhanyuan
