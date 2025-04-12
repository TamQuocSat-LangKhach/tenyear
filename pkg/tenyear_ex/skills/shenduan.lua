local shenduan = fk.CreateSkill {
  name = "ty_ex__shenduan",
}

Fk:loadTranslationTable{
  ["ty_ex__shenduan"] = "慎断",
  [":ty_ex__shenduan"] = "当你的黑色非锦囊牌因弃置而置入弃牌堆后，你可以将此牌当【兵粮寸断】使用（无距离限制）。",

  ["#ty_ex__shenduan-use"] = "慎断：你可以将这些牌当【兵粮寸断】使用",

  ["$ty_ex__shenduan1"] = "行军断策需慎之又慎！",
  ["$ty_ex__shenduan2"] = "为将者务当慎行谨断！",
}

shenduan:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shenduan.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              table.contains(player.room.discard_pile, info.cardId) then
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
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            table.contains(player.room.discard_pile, info.cardId) then
            local card = Fk:getCardById(info.cardId)
            if card.type ~= Card.TypeTrick and card.color == Card.Black then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end
    for _ = 1, #ids, 1 do
      if not player:hasSkill(shenduan.name) then return end
      ids = table.filter(ids, function(id)
        return table.contains(player.room.discard_pile, id)
      end)
      if #ids == 0 then break end
      event:setSkillData(self, "cancel_cost", false)
      event:setCostData(self, {cards = ids})
      self:doCost(event, target, player, data)
      if event:getSkillData(self, "cancel_cost") then
        event:setSkillData(self, "cancel_cost", false)
        break
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "shenduan_viewas",
      prompt = "#ty_ex__shenduan-use",
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        expand_pile = cards,
      },
    })
    if success and dat then
      event:setCostData(self, {extra_data = dat})
      return true
    else
      event:setSkillData(self, "cancel_cost", true)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self).extra_data
    room:useVirtualCard("supply_shortage", dat.cards, player, dat.targets, shenduan.name)
  end,
})

return shenduan
