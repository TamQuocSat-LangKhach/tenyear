local weiwan = fk.CreateSkill {
  name = "weiwan",
}

Fk:loadTranslationTable{
  ["weiwan"] = "媦婉",
  [":weiwan"] = "出牌阶段限一次，你可以弃置一张“琴”并选择一名其他角色，随机获得其区域内与此“琴”不同花色的牌各一张。若你获得的牌数为："..
  "1，其失去1点体力；2，你本回合对其使用牌无距离与次数限制；3，你本回合不能对其使用牌。",

  ["#weiwan"] = "媦婉：弃置一张“琴”，获得一名角色花色不同的牌各一张",

  ["$weiwan1"] = "繁花初成，所幸未晚于桑榆。",
  ["$weiwan2"] = "群胥泛舟，共载佳期若瑶梦。",
}

weiwan:addEffect("active", {
  anim_type = "control",
  prompt = "#weiwan",
  can_use = function(self, player)
    return player:usedSkillTimes(weiwan.name, Player.HistoryPhase) == 0
  end,
  card_num = 1,
  target_num = 1,
  card_filter = function (skill, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("qiqin") > 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local suit = Fk:getCardById(effect.cards[1]).suit
    room:throwCard(effect.cards, weiwan.name, player, player)
    if player.dead or target.dead then return end
    local cardsMap = {}
    for _, id in ipairs(target:getCardIds("hej")) do
      local suit2 = Fk:getCardById(id).suit
      if suit2 ~= Card.NoSuit and suit ~= suit2 then
        cardsMap[suit] = cardsMap[suit] or {}
        table.insert(cardsMap[suit], id)
      end
    end
    local get = {}
    for _, value in pairs(cardsMap) do
      table.insert(get, table.random(value))
    end
    if #get > 0 then
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonPrey, weiwan.name, nil, true, player)
      if target.dead then return end
      if #get == 1 then
        room:loseHp(target, 1, weiwan.name)
      elseif #get == 2 then
        room:addTableMark(player, "weiwan-turn", target.id)
      elseif #get == 3 then
        room:addTableMark(player, "weiwan_prohibit-turn", target.id)
      end
    end
  end,
})

weiwan:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and
      table.find(data.tos, function (p)
        return table.contains(player:getTableMark("weiwan-turn"), p.id)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

weiwan:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("weiwan-turn"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and to and table.contains(player:getTableMark("weiwan-turn"), to.id)
  end,
})

weiwan:addEffect("prohibit", {
  is_prohibited = function(self, player, to, card)
    return card and table.contains(player:getTableMark("weiwan_prohibit-turn"), to.id)
  end,
})

return weiwan
