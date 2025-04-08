local longyuan = fk.CreateSkill {
  name = "ty__longyuan",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ty__longyuan"] = "龙渊",
  [":ty__longyuan"] = "觉醒技，一名角色的结束阶段，若你本局游戏内发动过至少三次〖翊赞〗，你摸两张牌并回复1点体力，"..
  "将〖翊赞〗中的“两张牌”修改为“一张牌”。",

  ["$ty__longyuan1"] = "尔等不闻九霄雷鸣，亦不闻渊龙之啸乎？",
  ["$ty__longyuan2"] = "双龙战于玄黄地，渊潭浪涌惊四方。",
}

longyuan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(longyuan.name) and
      target.phase == Player.Finish and
      player:usedSkillTimes(longyuan.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes("ty__yizan", Player.HistoryGame) > 2
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, longyuan.name)
    if not player.dead and player:isWounded() then
      player.room:recover{
        num = 1,
        skillName = longyuan.name,
        who = player,
        recoverBy = player,
      }
    end
  end,
})

return longyuan
