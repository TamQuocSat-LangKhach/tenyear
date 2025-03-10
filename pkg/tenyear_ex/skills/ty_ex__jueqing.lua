local jueqing = fk.CreateSkill {
  name = "ty_ex__jueqing"
}

Fk:loadTranslationTable{
  ['ty_ex__jueqing'] = '绝情',
  ['#jueqing-invoke'] = '绝情：是否失去%arg点体力令即将对%dest造成的伤害翻倍',
  ['#ty_ex__jueqing_delay'] = '绝情',
  [':ty_ex__jueqing'] = '当你造成伤害时，若不为连环伤害且你未发动过此技能，你可以失去等量的体力，令伤害值翻倍，此伤害结算结束后，你失去此技能，获得〖绝情〗。',
  ['$ty_ex__jueqing1'] = '不知情之所起，亦不知情之所终。',
  ['$ty_ex__jueqing2'] = '唯有情字最伤人！',
}

jueqing:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jueqing) and not data.chain and
      player:usedSkillTimes(jueqing.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jueqing.name,
      prompt = "#jueqing-invoke::" .. data.to.id .. ":" .. data.damage,
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, data.damage, jueqing.name)
    data.damage = data.damage * 2
    data.extra_data = data.extra_data or {}
    data.extra_data.ty_ex__jueqing = data.extra_data.ty_ex__jueqing or {}
    table.insert(data.extra_data.ty_ex__jueqing, player.id)
  end,
})

jueqing:addEffect(fk.DamageFinished, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:hasSkill("ty_ex__jueqing", true) and data.extra_data and data.extra_data.ty_ex__jueqing and
      table.contains(data.extra_data.ty_ex__jueqing, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("ty_ex__jueqing")
    player.room:handleAddLoseSkills(player, "-ty_ex__jueqing|jueqing", nil, true, false)
  end,
})

return jueqing
