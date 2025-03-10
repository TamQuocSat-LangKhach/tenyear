local jichouw = fk.CreateSkill {
  name = "jichouw"
}

Fk:loadTranslationTable{
  ['jichouw'] = '集筹',
  ['jichouw_distribution'] = '集筹',
  ['#jichouw-distribution'] = '集筹：你可以将本回合使用过的牌交给每名角色各一张',
  ['@$jichouw'] = '集筹',
  [':jichouw'] = '结束阶段，若你于此回合内使用过的牌的牌名各不相同，你可以将弃牌堆中的这些牌交给你选择的角色各一张。然后你摸X张牌（X为其中此前没有以此法给出过的牌名数）。',
  ['$jichouw1'] = '备武枕戈，待天下风起之时。',
  ['$jichouw2'] = '定淮联兖，邀群士共襄大义。',
}

jichouw:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(jichouw.name) and player.phase == Player.Finish then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end

      local names = {}
      local cards = {}

      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == player.id then
          if table.contains(names, use.card.trueName) then
            cards = {}
            return true
          end

          table.insert(names, use.card.trueName)
          table.insertTableIfNeed(cards, Card:getIdList(use.card))
        end
      end, turn_event.id)

      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)

      if #cards > 0 then
        event:setCostData(self, cards)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(self))
    local targets = {}
    local moveInfos = {}
    local names = {}

    while true do
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "jichouw_distribution",
        prompt = "#jichouw-distribution",
        cancelable = true,
        extra_data = { expand_pile = cards, jichouw_cards = cards , jichouw_targets = targets },
        no_indicate = true
      })

      if success then
        local to = dat.targets[1]
        local give_cards = dat.cards

        table.insert(targets, to)
        table.removeOne(cards, give_cards[1])
        table.insertIfNeed(names, Fk:getCardById(give_cards[1]).trueName)

        table.insert(moveInfos, {
          ids = give_cards,
          fromArea = Card.DiscardPile,
          to = to,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonGive,
          proposer = player.id,
          skillName = jichouw.name,
        })

        if #cards == 0 then break end
      else
        break
      end
    end

    if #moveInfos > 0 then
      local x = 0
      local mark = player:getTableMark("@$jichouw")

      for _, name in ipairs(names) do
        if table.insertIfNeed(mark, name) then
          x = x + 1
        end
      end

      if x > 0 then
        room:setPlayerMark(player, "@$jichouw", mark)
      end

      room:moveCards(table.unpack(moveInfos))

      if x > 0 and not player.dead then
        player:drawCards(x, jichouw.name)
      end
    end
  end,
})

jichouw:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player)
    return player == target and data == self and player:getMark("@$jichouw") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, "@$jichouw", 0)
  end,
})

return jichouw
