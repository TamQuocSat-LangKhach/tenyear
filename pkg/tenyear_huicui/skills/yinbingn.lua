local yinbingn = fk.CreateSkill {
  name = "yinbingn",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yinbingn"] = "阴兵",
  [":yinbingn"] = "锁定技，你使用【杀】即将造成的伤害视为失去体力。当其他角色失去体力后，你摸一张牌。",
}

yinbingn:addEffect(fk.PreDamage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yinbingn.name) and
      data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local n = data.damage
    data:preventDamage()
    player.room:loseHp(data.to, n, yinbingn.name)
  end,
})

yinbingn:addEffect(fk.HpLost, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(yinbingn.name)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, yinbingn.name)
  end,
})

return yinbingn
