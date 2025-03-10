local yuxi = fk.CreateSkill {
  name = "yuxi"
}

Fk:loadTranslationTable{
  ['yuxi'] = '驭袭',
  ['@@yuxi-inhand'] = '驭袭',
  [':yuxi'] = '当你造成或受到伤害时，你可以摸一张牌，以此法获得的牌无次数限制。',
  ['$yuxi1'] = '任他千军来，我只一枪去！',
  ['$yuxi2'] = '长枪雪恨，斩尽胡马！'
}

yuxi:addEffect(fk.DamageCaused, {
  global = true,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, yuxi.name, nil, "@@yuxi-inhand")
  end
})

yuxi:addEffect(fk.DamageInflicted, {
  global = true,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, yuxi.name, nil, "@@yuxi-inhand")
  end
})

yuxi:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@@yuxi-inhand") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end
})

local yuxi_targetmod_spec = {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@yuxi-inhand") > 0
  end,
}
yuxi:addEffect('targetmod', yuxi_targetmod_spec)

return yuxi
