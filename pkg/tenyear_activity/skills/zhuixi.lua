local zhuixi = fk.CreateSkill {
  name = "zhuixi"
}

Fk:loadTranslationTable{
  ['zhuixi'] = '追袭',
  [':zhuixi'] = '锁定技，当你对其他角色造成伤害时，或当你受到其他角色造成的伤害时，若你与其翻面状态不同，此伤害+1。',
  ['$zhuixi1'] = '得势追击，胜望在握！',
  ['$zhuixi2'] = '诸将得令，追而袭之！',
}

zhuixi:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuixi.name) and data.from and data.to and
      ((data.from.faceup and not data.to.faceup) or (not data.from.faceup and data.to.faceup))
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

zhuixi:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuixi.name) and data.from and data.to and
      ((data.from.faceup and not data.to.faceup) or (not data.from.faceup and data.to.faceup))
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

return zhuixi
