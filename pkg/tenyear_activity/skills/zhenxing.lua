local zhenxing = fk.CreateSkill{
  name = "zhenxing"
}

Fk:loadTranslationTable{
  ['zhenxing'] = '镇行',
  ['#zhenxing-get'] = '镇行：你可以获得其中一张牌',
  [':zhenxing'] = '结束阶段开始时或当你受到伤害后，你可以观看牌堆顶三张牌，然后获得其中与其余牌花色均不同的一张牌。',
  ['$zhenxing1'] = '兵行万土，得御安危。',
  ['$zhenxing2'] = '边境镇威，万军难进。',
}

zhenxing:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(zhenxing.name) then
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = room:getNCards(3)
    local can_get = table.filter(cards, function(id)
      return not table.find(cards, function(id2)
        return id ~= id2 and Fk:getCardById(id).suit == Fk:getCardById(id2).suit
      end)
    end)

    local card, choice = room:askToChooseCardsAndChoices(player, {
      min_card_num = 0,
      max_card_num = 1,
      choices = {"OK"},
      skill_name = zhenxing.name,
      prompt = "#zhenxing-get",
      cancelable_choices = {"Cancel"},
      expand_pile = cards
    })

    local get = card[1]
    if get then
      table.removeOne(cards, get)
    end

    room:doBroadcastNotify("UpdateDrawPile", #room.draw_pile)

    if get then
      room:obtainCard(player.id, get, false, fk.ReasonJustMove)
    end
  end,
})

zhenxing:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    if player.phase == Player.Finish and player:hasSkill(zhenxing.name) then
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = room:getNCards(3)
    local can_get = table.filter(cards, function(id)
      return not table.find(cards, function(id2)
        return id ~= id2 and Fk:getCardById(id).suit == Fk:getCardById(id2).suit
      end)
    end)

    local card, choice = room:askToChooseCardsAndChoices(player, {
      min_card_num = 0,
      max_card_num = 1,
      choices = {"OK"},
      skill_name = zhenxing.name,
      prompt = "#zhenxing-get",
      cancelable_choices = {"Cancel"},
      expand_pile = cards
    })

    local get = card[1]
    if get then
      table.removeOne(cards, get)
    end

    room:doBroadcastNotify("UpdateDrawPile", #room.draw_pile)

    if get then
      room:obtainCard(player.id, get, false, fk.ReasonJustMove)
    end
  end,
})

return zhenxing
