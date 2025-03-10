local diou = fk.CreateSkill {
  name = "diou"
}

Fk:loadTranslationTable{
  ['diou'] = '低讴',
  ['@@tanban-inhand'] = '檀板',
  ['@@diou_showed'] = '已展示',
  ['#diou-card'] = '低讴：你可以展示一张非“檀板”牌，视为使用之。初次展示此牌则摸两张牌',
  [':diou'] = '当你使用“檀板”牌结算结束后，你可以展示一张不为“檀板”牌的手牌，若展示了基本牌或普通锦囊牌，你视为使用展示牌。若为你本回合第一次展示此牌或与使用的“檀板”牌牌名相同，你摸两张牌。',
  ['$diou1'] = '一日不见兮，思之如狂。',
  ['$diou2'] = '有一美人兮，见之不忘。',
}

diou:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(diou.name) and not player:isKongcheng() and
      (data.extra_data or {}).usingTanban
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids, record = {}, player:getTableMark("diou-turn")
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      if Fk:getCardById(id):getMark("@@tanban-inhand") == 0 then
        table.insert(ids, id)
        if table.contains(record, id) then
          room:setCardMark(Fk:getCardById(id), "@@diou_showed", 1)
        end
      end
    end
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#diou-card",
      skill_name = diou.name,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
    end
    for _, id in ipairs(ids) do
      if Fk:getCardById(id):getMark("@@diou_showed") ~= 0 then
        room:setCardMark(Fk:getCardById(id), "@@diou_showed", 0)
      end
    end
    return #cards > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local chosen = event:getCostData(self).cards[1]
    local draw = not table.contains(player:getTableMark("diou-turn"), chosen)
    if draw then
      room:addTableMark(player, "diou-turn", chosen)
    else
      draw = Fk:getCardById(chosen).trueName == data.card.trueName
    end
    player:showCards({chosen})
    local card = Fk:getCardById(chosen)
    if card.type == Card.TypeBasic or card:isCommonTrick() then
      U.askForUseVirtualCard(room, player, card.name, nil, diou.name, nil, false, true, false, true)
    end
    if draw and not player.dead then
      player:drawCards(2, diou.name)
    end
  end,
})

diou:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(diou.name) and data.card:getMark("@@tanban-inhand") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.usingTanban = true
  end,
})

return diou
