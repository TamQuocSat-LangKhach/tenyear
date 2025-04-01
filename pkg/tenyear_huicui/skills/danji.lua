local danji = fk.CreateSkill {
  name = "ty__danji",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ty__danji"] = "单骑",
  [":ty__danji"] = "觉醒技，准备阶段，若你区域里的牌数大于体力值，你减1点体力上限，回复体力至体力上限，摸X张牌（X为你以此法回复的体力值），"..
  "获得〖马术〗和〖怒嗔〗。",

  ["$ty__danji1"] = "单骑护嫂千里，只为桃园之义！",
  ["$ty__danji2"] = "独身远涉，赤心归国！",
}

danji:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(danji.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(danji.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getCardIds("hej") > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    local n = player.maxHp - player.hp
    if n > 0 then
      room:recover{
        who = player,
        num = n,
        recoverBy = player,
        skillName = danji.name,
      }
      if player.dead then return end
      player:drawCards(n, danji.name)
      if player.dead then return end
    end
    room:handleAddLoseSkills(player, "mashu|nuchen")
  end,
})

return danji
