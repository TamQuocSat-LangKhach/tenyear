local yinbingn = fk.CreateSkill {
  name = "yinbingn"
}

Fk:loadTranslationTable{
  ['yinbingn'] = '阴兵',
  [':yinbingn'] = '锁定技，你使用【杀】即将造成的伤害视为失去体力。当其他角色失去体力后，你摸一张牌。',
}

yinbingn:addEffect(fk.PreDamage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and data.card:trueName() == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(data.to, data.damage, yinbingn.name)
    return true
  end,
})

yinbingn:addEffect(fk.HpLost, {
  can_trigger = function(self, event, target, player, data)
    return target ~= player
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, yinbingn.name)
  end,
})

return yinbingn
