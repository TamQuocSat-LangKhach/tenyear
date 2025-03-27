local yiyong = fk.CreateSkill {
  name = "yiyong"
}

Fk:loadTranslationTable{
  ['yiyong'] = '异勇',
  ['#yiyong-invoke'] = '异勇：你可以弃置任意张牌，令 %dest 弃置任意张牌，根据双方弃牌点数之和执行效果',
  ['#yiyong-discard'] = '异勇：弃置至少一张牌',
  [':yiyong'] = '每当你对其他角色造成伤害时，你可以和该角色同时弃置至少一张牌（该角色没牌则不弃）。若你弃置的牌的点数之和：不大于其，你摸X张牌（X为该角色弃置的牌数+1）；不小于其，此伤害+1。',
  ['$yiyong1'] = '关氏鼠辈，庞令明之子来邪！',
  ['$yiyong2'] = '凭一腔勇力，父仇定可报还。',
}

yiyong:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yiyong.name)
      and data.to and data.to ~= player and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = yiyong.name,
      cancelable = true,
      prompt = "#yiyong-invoke::"..data.to.id
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from_cards = event:getCostData(self).cards
    local to_cards = player.room:askToDiscard(data.to, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = yiyong.name,
      cancelable = false,
      prompt = "#yiyong-discard"
    })
    local n1, n2 = 0, 0
    for _, id in ipairs(from_cards) do
      n1 = n1 + Fk:getCardById(id).number
    end
    for _, id in ipairs(to_cards) do
      n2 = n2 + Fk:getCardById(id).number
    end
    room:moveCards({
      from = player.id,
      ids = from_cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonDiscard,
      proposer = player.id,
    },{
        from = data.to.id,
        ids = to_cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = data.to.id,
      })
    if n1 <= n2 and #to_cards > 0 and not player.dead then
      player:drawCards(#to_cards + 1, yiyong.name)
    end
    if n1 >= n2 then
      data.damage = data.damage + 1
    end
  end,
})

return yiyong
