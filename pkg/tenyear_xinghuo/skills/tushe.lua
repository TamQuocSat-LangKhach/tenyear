local tushe = fk.CreateSkill {
  name = "tushe"
}

Fk:loadTranslationTable{
  ['tushe'] = '图射',
  [':tushe'] = '当你使用非装备牌指定目标后，若你没有基本牌，则你可以摸X张牌（X为此牌指定的目标数）。',
  ['$tushe1'] = '据险以图进，备策而施为！',
  ['$tushe2'] = '夫战者，可时以奇险之策而图常谋！',
}

tushe:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tushe.name) and data.card.type ~= Card.TypeEquip and data.firstTarget and
      not table.find(player:getCardIds(Player.Hand), function(id) return Fk:getCardById(id).type == Card.TypeBasic end) and
      #AimGroup:getAllTargets(data.tos) > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#AimGroup:getAllTargets(data.tos), tushe.name)
  end,
})

return tushe
