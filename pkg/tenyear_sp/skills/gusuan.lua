local gusuan = fk.CreateSkill {
  name = "gusuan",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["gusuan"] = "股算",
  [":gusuan"] = "觉醒技，每个回合结束时，若圆环剩余点数为3个，你减1点体力上限，并修改〖割圆〗。",

  ["$gusuan1"] = "勾中容横，股中容直，可知其玄五。",
  ["$gusuan2"] = "累矩连索，类推衍化，开立而得法。",
}

gusuan:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gusuan.name) and player:usedSkillTimes(gusuan.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local mark = player:getMark("@[geyuan]")
    return type(mark) == "table" and #mark.all == 3
  end,
  on_use = function(self, event, target, player, data)
    player.room:changeMaxHp(player, -1)
  end,
})

return gusuan
