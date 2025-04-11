local jueqing = fk.CreateSkill {
  name = "ty_ex__jueqing",
}

Fk:loadTranslationTable{
  ["ty_ex__jueqing"] = "绝情",
  [":ty_ex__jueqing"] = "当你造成伤害时，你可以失去等量的体力，令伤害值翻倍。若如此做，此伤害结算结束后，你失去此技能，获得〖绝情〗。",

  ["#ty_ex__jueqing-invoke"] = "绝情：是否失去%arg点体力，令你对 %dest 造成的伤害翻倍？",

  ["$ty_ex__jueqing1"] = "不知情之所起，亦不知情之所终。",
  ["$ty_ex__jueqing2"] = "唯有情字最伤人！",
}

jueqing:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jueqing.name) and not data.chain and
      player:usedSkillTimes(jueqing.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jueqing.name,
      prompt = "#ty_ex__jueqing-invoke::"..data.to.id..":"..data.damage,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, data.damage, jueqing.name)
    data:changeDamage(data.damage)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty_ex__jueqing = player
  end,
})

jueqing:addEffect(fk.DamageFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:hasSkill("ty_ex__jueqing", true) and
      data.extra_data and data.extra_data.ty_ex__jueqing == player
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-ty_ex__jueqing|jueqing")
  end,
})

return jueqing
