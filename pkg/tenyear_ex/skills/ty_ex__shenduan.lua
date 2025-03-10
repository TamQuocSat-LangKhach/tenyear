local ty_ex__shenduan = fk.CreateSkill {
  name = "ty_ex__shenduan"
}

Fk:loadTranslationTable{
  ['ty_ex__shenduan'] = '慎断',
  ['ty_ex__shenduan_active'] = '慎断',
  ['#ty_ex__shenduan-use'] = '慎断：你可以将这些牌当【兵粮寸断】使用',
  [':ty_ex__shenduan'] = '当你的黑色非锦囊牌因弃置而置入弃牌堆时，你可以将此牌当【兵粮寸断】使用（无距离限制）。',
  ['$ty_ex__shenduan1'] = '行军断策需慎之又慎！',
  ['$ty_ex__shenduan2'] = '为将者务当慎行谨断！',
}

ty_ex__shenduan:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty_ex__shenduan) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip)
              and player.room:getCardArea(info.cardId) == Card.DiscardPile then
              local card = Fk:getCardById(info.cardId)
              if card.type ~= Card.TypeTrick and card.color == Card.Black then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip)
            and player.room:getCardArea(info.cardId) == Card.DiscardPile then
            local card = Fk:getCardById(info.cardId)
            if card.type ~= Card.TypeTrick and card.color == Card.Black then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end
    for i = 1, #ids, 1 do
      if player.dead then break end
      local cards = table.filter(ids, function(id) return player.room:getCardArea(id) == Card.DiscardPile end)
      if #cards == 0 then break end
      skill.cancel_cost = false
      skill:doCost(event, nil, player, cards)
      if skill.cancel_cost then
        skill.cancel_cost = false
        break
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, ty_ex__shenduan.name, data)
    local _, dat = room:askToUseRealCard(player, {
      pattern = data,
      skill_name = "ty_ex__shenduan_active",
      prompt = "#ty_ex__shenduan-use",
      cancelable = true,
      bypass_distances = true
    })
    if dat then
      event:setCostData(skill, dat)
      return true
    else
      skill.cancel_cost = true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:useVirtualCard("supply_shortage", event:getCostData(skill).cards, player, room:getPlayerById(event:getCostData(skill).targets[1]), ty_ex__shenduan.name)
  end,
})

return ty_ex__shenduan
