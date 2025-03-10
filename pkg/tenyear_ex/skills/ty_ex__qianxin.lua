local ty_ex__qianxin = fk.CreateSkill {
  name = "ty_ex__qianxin"
}

Fk:loadTranslationTable{
  ['ty_ex__qianxin'] = '潜心',
  ['ty_ex__jianyan'] = '荐言',
  [':ty_ex__qianxin'] = '觉醒技，当你造成伤害后，若你已受伤，你减1点体力上限，并获得〖荐言〗。',
  ['$ty_ex__qianxin1'] = '弃剑执笔，修习韬略。',
  ['$ty_ex__qianxin2'] = '休武兴文，专研筹划。',
}

ty_ex__qianxin:addEffect(fk.Damage, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__qianxin.name) and
      player:usedSkillTimes(ty_ex__qianxin.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.hp < player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "ty_ex__jianyan")
  end,
})

return ty_ex__qianxin
