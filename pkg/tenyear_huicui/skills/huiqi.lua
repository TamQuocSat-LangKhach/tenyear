local huiqi = fk.CreateSkill{
  name = "ty__huiqi",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ty__huiqi"] = "彗企",
  [":ty__huiqi"] = "觉醒技，每个回合结束时，若本回合仅有包括你的三名角色成为过牌的目标，你获得〖偕举〗并执行一个额外的回合。",

  ["$ty__huiqi1"] = "老夫企踵西望，在殿奸邪可击。",
  ["$ty__huiqi2"] = "司马氏祸国乱政，天之所以殃之。",
}

huiqi:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(huiqi.name) and player:usedSkillTimes(huiqi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      for _, p in ipairs(use.tos) do
        table.insertIfNeed(targets, p)
      end
    end, Player.HistoryTurn)
    return #targets == 3 and table.contains(targets, player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "ty__xieju")
    player:gainAnExtraTurn(true, huiqi.name)
  end,
})

return huiqi
