local zhizhe = fk.CreateSkill {
  name = "zhizhe",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zhizhe"] = "智哲",
  [":zhizhe"] = "限定技，出牌阶段，你可以复制一张手牌。此牌因你使用或打出而进入弃牌堆后，你获得且本回合不能再使用或打出之。",

  ["#zhizhe"] = "智哲：获得一张手牌的复制！",

  ["$zhizhe1"] = "轻舟载浊酒，此去，我欲借箭十万。",
  ["$zhizhe2"] = "主公有多大胆略，亮便有多少谋略。",
}

zhizhe:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#zhizhe",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedEffectTimes(zhizhe.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local c = Fk:getCardById(effect.cards[1], true)
    local card = room:printCard(c.name, c.suit, c.number)
    room:addTableMark(player, zhizhe.name, card.id)
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, zhizhe.name, nil, false, player)
  end
})

zhizhe:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark(zhizhe.name) ~= 0 then
      local move_event = player.room.logic:getCurrentEvent()
      local parent_event = move_event.parent
      if parent_event and (parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard) then
        local parent_data = parent_event.data
        if parent_data.from == player then
          local card_ids = Card:getIdList(parent_data.card)
          local ids = {}
          for _, move in ipairs(data) do
            if move.toArea == Card.DiscardPile then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.Processing and table.contains(player.room.discard_pile, info.cardId) and
                  table.contains(card_ids, info.cardId) and
                  table.contains(player:getTableMark(zhizhe.name), info.cardId) and
                  not table.contains(player:getTableMark("zhizhe-turn"), info.cardId) then
                  table.insertIfNeed(ids, info.cardId)
                end
              end
            end
          end
          if #ids > 0 then
            event:setCostData(self, {cards = ids})
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    local mark = player:getTableMark("zhizhe-turn")
    table.insertTableIfNeed(mark, cards)
    room:setPlayerMark(player, "zhizhe-turn", mark)
    room:obtainCard(player, cards, true, fk.ReasonJustMove, player, zhizhe.name)
  end,
})

zhizhe:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("zhizhe-turn") ~= 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return table.find(subcards, function (id)
        return table.contains(player:getTableMark("zhizhe-turn"), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("zhizhe-turn") ~= 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return table.find(subcards, function (id)
        return table.contains(player:getTableMark("zhizhe-turn"), id)
      end)
    end
  end,
})

return zhizhe
