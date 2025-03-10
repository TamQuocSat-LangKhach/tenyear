local huiwan = fk.CreateSkill {
  name = "huiwan"
}

Fk:loadTranslationTable{
  ['huiwan'] = '会玩',
  ['#huiwan-choice'] = '会玩：你可选择至多 %arg 个牌名，本次改为摸所选牌名的牌',
  [':huiwan'] = '每回合每种牌名限一次，当你摸牌时，你可以选择至多等量牌堆中有的基本牌或普通锦囊牌牌名，然后改为从牌堆中获得你选择的牌。',
  ['$huiwan1'] = '金珠弹黄鹂，玉带做秋千，如此游戏人间。',
  ['$huiwan2'] = '小爷横行江东，今日走马、明日弄鹰。',
}

huiwan:addEffect(fk.BeforeDrawCard, {
  can_trigger = function(self, event, target, player, data)
    if not (player == target and player:hasSkill(huiwan) and data.num > 0) then
      return false
    end

    local availableNames = table.filter(
      player.room:getTag("huiwanAllCardNames") or {},
      function(name)
        return not table.contains(player:getTableMark("huiwan_card_names-turn"), name)
      end
    )

    if #availableNames > 0 then
      return 
      table.find(
        player.room.draw_pile,
        function(id) return table.contains(availableNames, Fk:getCardById(id).trueName) end
      )
    end

    return false
  end,

  on_cost = function(self, event, target, player, data)
    local room = player.room
    local allCardNames = table.filter(
      room:getTag("huiwanAllCardNames") or {},
      function(name)
        return not table.contains(player:getTableMark("huiwan_card_names-turn"), name)
      end
    )

    local chioces = {}
    for _, name in ipairs(allCardNames) do
      if table.find(room.draw_pile, function(id) return Fk:getCardById(id).trueName == name end) then
        table.insert(chioces, name)
      end
    end

    local result = room:askToChoices(player, {
      choices = chioces,
      min_num = 1,
      max_num = data.num,
      skill_name = huiwan.name,
      prompt = "#huiwan-choice:::" .. data.num,
    })
    if #result > 0 then
      event:setCostData(self, result)
      return true
    end

    return false
  end,

  on_use = function(self, event, target, player, data)
    local room = player.room
    local namesChosen = table.simpleClone(event:getCostData(self))
    local cardNamesRecord = player:getTableMark("huiwan_card_names-turn")
    table.insertTableIfNeed(cardNamesRecord, table.map(namesChosen, function(name) return name end))
    room:setPlayerMark(player, "huiwan_card_names-turn", cardNamesRecord)

    local toDraw = {}
    for i = #room.draw_pile, 1, -1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if table.contains(namesChosen, card.trueName) then
        table.removeOne(namesChosen, card.trueName)
        table.insert(toDraw, card.id)
      end
    end

    if #toDraw > 0 then
      room:obtainCard(player, toDraw, false, fk.ReasonPrey, player.id, huiwan.name)
    end

    data.num = data.num - #toDraw
    return data.num < 1
  end,
})

huiwan:addEffect(fk.EventAcquireSkill, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data == self and not player.room:getTag("huiwanAllCardNames")
  end,

  on_refresh = function(self, event, target, player, data)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeBasic or card:isCommonTrick()) then
        table.insertIfNeed(allCardNames, card.trueName)
      end
    end

    player.room:setTag("huiwanAllCardNames", allCardNames)
  end,
})

return huiwan
