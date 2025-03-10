local ty__jiqiao = fk.CreateSkill {
  name = "ty__jiqiao"
}

Fk:loadTranslationTable{
  ['ty__jiqiao'] = '机巧',
  ['#ty__jiqiao-invoke'] = '机巧：你可以弃置任意张牌，亮出牌堆顶等量牌（每有一张装备牌额外亮出一张），获得非装备牌',
  [':ty__jiqiao'] = '出牌阶段开始时，你可以弃置任意张牌，然后你亮出牌堆顶等量的牌，你弃置的牌中每有一张装备牌，则多亮出一张牌。然后你获得其中的非装备牌。',
  ['$ty__jiqiao1'] = '机关将作之术，在乎手巧心灵。',
  ['$ty__jiqiao2'] = '机巧藏于心，亦如君之容。',
}

ty__jiqiao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty__jiqiao) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player)
    local cards = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = ty__jiqiao.name,
      cancelable = true,
      prompt = "#ty__jiqiao-invoke",
    })
    if #cards > 0 then
      event:setCostData(self, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:throwCard(event:getCostData(self), ty__jiqiao.name, player, player)
    if player.dead then return end
    local n = 0
    for _, id in ipairs(event:getCostData(self)) do
      if Fk:getCardById(id).type == Card.TypeEquip then
        n = n + 2
      else
        n = n + 1
      end
    end
    local cards = room:getNCards(n)
    room:moveCards{
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = ty__jiqiao.name,
      proposer = player.id,
    }
    local get = {}
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).type ~= Card.TypeEquip then
        table.insert(get, cards[i])
        table.removeOne(cards, cards[i])
      end
    end
    if #get > 0 then
      room:delay(1000)
      room:obtainCard(player.id, get, true, fk.ReasonJustMove)
    end
    if #cards > 0 then
      room:delay(1000)
      room:moveCards{
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = ty__jiqiao.name,
      }
    end
  end,
})

return ty__jiqiao
