local kangli = fk.CreateSkill {
  name = "kangli"
}

Fk:loadTranslationTable{
  ['kangli'] = '伉厉',
  ['@@kangli-inhand'] = '伉厉',
  [':kangli'] = '当你造成或受到伤害后，你可以摸两张牌，然后你下次造成伤害时弃置这些牌。',
  ['$kangli1'] = '地界纷争皋陶难断，然图藏天府，坐上可明。',
  ['$kangli2'] = '正至歉岁，难征百姓于役，望陛下明鉴。',
}

kangli:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(kangli.name) and target == player
  end,
  on_cost = function (skill, event, target, player)
    return player.room:askToSkillInvoke(player, { skill_name = kangli.name })
  end,
  on_use = function (skill, event, target, player)
    local room = player.room
    player:drawCards(2, kangli.name, nil, "@@kangli-inhand")
  end,
})

kangli:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player)
    return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@kangli-inhand") > 0 end) and target == player
  end,
  on_cost = function (skill, event, target, player)
    return true
  end,
  on_use = function (skill, event, target, player)
    local room = player.room
    local ids = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@kangli-inhand") > 0 end)
    room:throwCard(ids, kangli.name, player, player)
  end,
})

return kangli
