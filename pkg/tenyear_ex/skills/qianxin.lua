local qianxin = fk.CreateSkill {
  name = "ty_ex__qianxin",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["ty_ex__qianxin"] = "潜心",
  [":ty_ex__qianxin"] = "觉醒技，当你造成伤害后，若你已受伤，你减1点体力上限，获得〖荐言〗。",

  ["$ty_ex__qianxin1"] = "弃剑执笔，修习韬略。",
  ["$ty_ex__qianxin2"] = "休武兴文，专研筹划。",
}

qianxin:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qianxin.name) and
      player:usedSkillTimes(qianxin.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "ty_ex__jianyan")
  end,
})

return qianxin
