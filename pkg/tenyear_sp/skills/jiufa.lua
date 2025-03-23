local jiufa = fk.CreateSkill {
  name = "jiufa",
}

Fk:loadTranslationTable{
  ["jiufa"] = "九伐",
  [":jiufa"] = "当你每累计使用或打出九张不同牌名的牌后，你可以亮出牌堆顶的九张牌，然后若其中有点数相同的牌，你选择并获得其中每个重复点数的牌各一张。",

  ["#jiufa-invoke"] = "九伐：是否亮出牌堆顶九张牌，获得重复点数的牌各一张",
  ["#jiufa"] = "九伐：从亮出的牌中获得每个重复点数的牌各一张",

  ["$jiufa1"] = "九伐中原，以圆先帝遗志。",
  ["$jiufa2"] = "日日砺剑，相报丞相厚恩。",
}

Fk:addPoxiMethod{
  name = "jiufa",
  card_filter = function(to_select, selected, data, extra_data)
    return table.contains(extra_data.get, to_select) and
      not table.find(selected, function (id)
        return Fk:getCardById(id).number == Fk:getCardById(to_select).number
      end)
  end,
  feasible = function (selected, data, extra_data)
    return #selected > 0
  end,
}

local spec = {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiufa.name) and
      not table.contains(player:getTableMark(jiufa.name), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(player, jiufa.name, data.card.trueName)
    if #player:getTableMark(jiufa.name) < 9 or not room:askToSkillInvoke(player, {
      skill_name = jiufa.name,
      prompt = "#jiufa-invoke",
    }) then return false end
    room:setPlayerMark(player, jiufa.name, 0)
    local cards = room:getNCards(9)
    room:turnOverCardsFromDrawPile(player, cards, jiufa.name)
    local get = table.filter(cards, function (id)
      return table.find(cards, function (id2)
        return id ~= id2 and Fk:getCardById(id).number == Fk:getCardById(id2).number
      end)
    end)
    local throw = table.filter(cards, function (id)
      return not table.contains(get, id)
    end)
    if #get > 0 then
      local result = room:askToPoxi(player, {
        poxi_type = jiufa.name,
        data = {
          { jiufa.name, cards },
        },
        extra_data = {
          get = get,
          throw = throw,
        },
        cancelable = false,
      })
      if #result == 0 then
        result = get
      end
      if #get > 0 then
        room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, jiufa.name, nil, true, player)
      end
    else
      room:delay(1000)
    end
    room:cleanProcessingArea(cards)
  end,
}

jiufa:addEffect(fk.CardUsing, spec)
jiufa:addEffect(fk.CardResponding, spec)

jiufa:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, jiufa.name, 0)
end)

return jiufa
