local jiqiao = fk.CreateSkill {
  name = "ty__jiqiao",
}

Fk:loadTranslationTable{
  ["ty__jiqiao"] = "机巧",
  [":ty__jiqiao"] = "出牌阶段开始时，你可以弃置任意张牌，然后你亮出牌堆顶等量的牌，你弃置的牌中每有一张装备牌，则多亮出一张牌。"..
  "然后你获得其中的非装备牌。",

  ["#ty__jiqiao-invoke"] = "机巧：你可以弃置任意张牌，亮出牌堆顶等量牌（每有一张装备牌额外亮出一张），获得非装备牌",

  ["$ty__jiqiao1"] = "机关将作之术，在乎手巧心灵。",
  ["$ty__jiqiao2"] = "机巧藏于心，亦如君之容。",
}

jiqiao:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiqiao.name) and player.phase == Player.Play and
      not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = jiqiao.name,
      prompt = "#ty__jiqiao-invoke",
      cancelable = true,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, id in ipairs(event:getCostData(self).cards) do
      if Fk:getCardById(id).type == Card.TypeEquip then
        n = n + 2
      else
        n = n + 1
      end
    end
    room:throwCard(event:getCostData(self).cards, jiqiao.name, player, player)
    if player.dead then return end
    local cards = room:getNCards(n)
    room:turnOverCardsFromDrawPile(player, cards, jiqiao.name)
    room:delay(1000)
    local ids = table.filter(cards, function (id)
      return Fk:getCardById(id).type ~= Card.TypeEquip
    end)
    if #ids > 0 then
      room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, jiqiao.name, nil, true, player)
    end
    room:cleanProcessingArea(cards)
  end,
})

return jiqiao
