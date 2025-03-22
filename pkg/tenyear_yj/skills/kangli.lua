local kangli = fk.CreateSkill {
  name = "kangli",
}

Fk:loadTranslationTable{
  ["kangli"] = "伉厉",
  [":kangli"] = "当你造成或受到伤害后，你可以摸两张牌，然后你下次造成伤害时弃置这些牌。",

  ["@@kangli-inhand"] = "伉厉",

  ["$kangli1"] = "地界纷争皋陶难断，然图藏天府，坐上可明。",
  ["$kangli2"] = "正至歉岁，难征百姓于役，望陛下明鉴。",
}

local spec = {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kangli.name)
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, kangli.name, nil, "@@kangli-inhand")
  end,
}

kangli:addEffect(fk.Damage, spec)
kangli:addEffect(fk.Damaged, spec)

kangli:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@kangli-inhand") > 0 and not player:prohibitDiscard(id)
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getMark("@@kangli-inhand") > 0 and not player:prohibitDiscard(id)
    end)
    room:throwCard(ids, kangli.name, player, player)
  end,
})

return kangli
