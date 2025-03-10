local busuan = fk.CreateSkill {
  name = "busuan"
}

Fk:loadTranslationTable{
  ['busuan'] = '卜算',
  ['#busuan-active'] = '发动 卜算，选择一名其他角色，控制其下个摸牌阶段的摸到的牌的牌名',
  ['#busuan-choose'] = '卜算：选择至多两个卡名，作为%arg下次摸牌阶段摸到的牌',
  [':busuan'] = '出牌阶段限一次，你可以选择一名其他角色，然后选择至多两张不同的卡牌名称（限基本牌或锦囊牌）。该角色下次摸牌阶段摸牌时，改为从牌堆或弃牌堆中获得你选择的牌。',
  ['$busuan1'] = '今日一卦，便知命数。',
  ['$busuan2'] = '喜仰视星辰，夜不肯寐。',
}

busuan:addEffect('active', {
  anim_type = "control",
  prompt = "#busuan-active",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(busuan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local names = player:getMark("busuan_names")
    if type(names) ~= "table" then
      --这里其实应该用真实卡名的，但是线上不是
      names = U.getAllCardNames("btd")
      room:setPlayerMark(player, "busuan_names", names)
    end
    local mark = target:getTableMark(busuan.name)
    table.insertTable(mark, room:askToChoices(player, {
      choices = names,
      min_num = 1,
      max_num = 2,
      skill_name = busuan.name,
      prompt = "#busuan-choose::" .. target.id,
    }))
    room:setPlayerMark(target, busuan.name, mark)
  end,
})

busuan:addEffect(fk.BeforeDrawCard, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and data.num > 0 and player.phase == Player.Draw and type(player:getMark(busuan.name)) == "table"
    --FIXME: can't find skillName(game_rule)!!
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local card_names = player:getMark(busuan.name)
    for i = 1, #card_names, 1 do
      table.insert(cards, -1)
    end
    for i = 1, #card_names, 1 do
      if cards[i] == -1 then
        local name = card_names[i]
        local x = #table.filter(card_names, function (card_name)
          return card_name == name 
        end)

        local tosearch = room:getCardsFromPileByRule(".|.|.|.|" .. name, x, "discardPile")
        if #tosearch < x then
          table.insertTable(tosearch, room:getCardsFromPileByRule(".|.|.|.|" .. name, x - #tosearch))
        end

        for i2 = 1, #card_names, 1 do
          if card_names[i2] == name then
            if #tosearch > 0 then
              cards[i2] = tosearch[1]
              table.remove(tosearch, 1)
            else
              cards[i2] = -2
            end
          end
        end
      end
    end
    local to_get = {}
    local card_names_copy = table.clone(card_names)
    for i = 1, #card_names, 1 do
      if #to_get >= data.num then break end
      if cards[i] > -1 then
        table.insert(to_get, cards[i])
        table.removeOne(card_names_copy, card_names[i])
      end
    end

    room:setPlayerMark(player, busuan.name, (#card_names_copy > 0) and card_names_copy or 0)

    data.num = data.num - #to_get

    if #to_get > 0 then
      room:moveCards({
        ids = to_get,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = busuan.name,
        moveVisible = false,
      })
    end
  end,
})

return busuan
