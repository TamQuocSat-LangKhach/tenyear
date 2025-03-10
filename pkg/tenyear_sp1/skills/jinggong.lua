local jinggong = fk.CreateSkill {
  name = "jinggong"
}

Fk:loadTranslationTable{
  ['jinggong'] = '精弓',
  ['#jinggong-viewas'] = '发动 精弓，将装备牌当【杀】使用，无距离限制且伤害值基数为你至目标的距离',
  ['#jinggong_trigger'] = '精弓',
  [':jinggong'] = '你可以将装备牌当无距离限制的【杀】使用，此【杀】的伤害基数值改为X（X为你至第一名目标角色的距离且至多为5）。',
  ['$jinggong1'] = '屈臂发弓，亲射猛虎。',
  ['$jinggong2'] = '幼习弓弩，正为此时！',
}

jinggong:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#jinggong-viewas",
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local card = Fk:cloneCard("slash")
    card:addSubcard(cards[1])
    card.skillName = jinggong.name
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})

jinggong:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if player == target and not player.dead and not player:isRemoved() and table.contains(data.card.skillNames, jinggong.name) then
      local room = player.room
      local tos = U.getActualUseTargets(room, data, event)
      if #tos == 0 then return false end
      room:sortPlayersByAction(tos)
      local to = room:getPlayerById(tos[1])
      if to:isRemoved() then return false end
      event:setCostData(self, math.min(player:distanceTo(to), 5) - 1)
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local cost_data = event:getCostData(self)
    data.additionalDamage = (data.additionalDamage or 0) + cost_data
  end,
})

jinggong:addEffect('targetmod', {
  bypass_distances =  function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, jinggong.name)
  end,
})

return jinggong
