local laoyan = fk.CreateSkill{
  name = "laoyan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["laoyan"] = "劳燕",
  [":laoyan"] = "锁定技，其他角色使用牌指定包括你在内的多个目标后，此牌对其他目标无效，你从牌堆获得点数小于此牌的牌每个点数各一张，"..
  "当前回合结束时弃置这些牌。",

  ["@@laoyan-inhand-turn"] = "劳燕",

  ["$laoyan1"] = "",
  ["$laoyan2"] = "",
}

laoyan:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(laoyan.name) and
      data.from ~= player and #data.use.tos > 1
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    for _, p in ipairs(data.use.tos) do
      if p ~= player then
        table.insertIfNeed(data.use.nullifiedTargets, p)
      end
    end
    if data.card.number > 1 then
      local cards = {}
      for i = 1, data.card.number - 1 do
        table.insertTable(cards, room:getCardsFromPileByRule(".|"..i))
      end
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, laoyan.name, nil, false, player, "@@laoyan-inhand-turn")
      end
    end
  end,
})

laoyan:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@laoyan-inhand-turn") > 0
    end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@laoyan-inhand-turn") > 0 and not player:prohibitDiscard(id)
    end)
    if #cards > 0 then
      room:throwCard(cards, laoyan.name, player, player)
    end
  end,
})

return laoyan
