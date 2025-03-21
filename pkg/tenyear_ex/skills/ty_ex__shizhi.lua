local ty_ex__shizhi = fk.CreateSkill {
  name = "ty_ex__shizhi"
}

Fk:loadTranslationTable{
  ['ty_ex__shizhi'] = '矢志',
  [':ty_ex__shiz__shizhi'] = '锁定技，当你的体力值为1时，你的【闪】视为【杀】；当你使用这些【杀】造成伤害后，你回复1点体力。',
}

ty_ex__shizhi:addEffect('filter', {
  card_filter = function(self, player, to_select)
    return player:hasSkill(ty_ex__shizhi.name) and player.hp == 1 and to_select.name == "jink" and
      (table.contains(player.player_cards[Player.Hand], to_select.id))
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
})

ty_ex__shizhi:addEffect(fk.Damage, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    return player == target and player:hasSkill(ty_ex__shizhi.name) and data.card and player:isWounded()
      and table.contains(data.card.skillNames, ty_ex__shizhi.name)
  end,
  on_use = function (self, event, target, player, data)
    player:broadcastSkillInvoke("ty_ex__shizhi")
    player.room:notifySkillInvoked(player, "ty_ex__shizhi", "defensive")
    player.room:recover { num = 1, skillName = ty_ex__shizhi.name, who = player, recoverBy = player}
  end,
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(ty_ex__shizhi.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      Fk:filterCard(id, player)
    end
  end,
})

return ty_ex__shizhi
