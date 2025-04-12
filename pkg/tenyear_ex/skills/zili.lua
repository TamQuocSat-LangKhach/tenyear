local zili = fk.CreateSkill {
  name = "ty_ex__zili",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ty_ex__zili"] = "自立",
  [":ty_ex__zili"] = "觉醒技，准备阶段，若“权”的数量不小于3，你回复1点体力并摸两张牌，然后减1点体力上限，获得技能〖排异〗。",

  ["$ty_ex__zili1"] = "烧去剑阁八百里，蜀中自有一片天！",
  ["$ty_ex__zili2"] = "天下风流出我辈，一遇风云便化龙。",
}

zili:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zili.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(zili.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("zhonghui_quan") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = zili.name,
      }
      if player.dead then return end
    end
    player:drawCards(2, zili.name)
    if player.dead then return end
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "ty_ex__paiyi")
  end,
})

return zili
