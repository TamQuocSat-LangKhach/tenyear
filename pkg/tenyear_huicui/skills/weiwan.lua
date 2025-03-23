local weiwan = fk.CreateSkill {
  name = "weiwan"
}

Fk:loadTranslationTable{
  ['weiwan'] = '媦婉',
  ['#weiwan-active'] = '发动 媦婉，选择一张“琴”弃置并选择一名其他角色',
  ['qiqin'] = '绮琴',
  [':weiwan'] = '出牌阶段限一次，你可以弃置一张“琴”并选择一名其他角色，随机获得其区域内与此“琴”不同花色的牌各一张。若你获得的牌数为：1，其失去1点体力；2，你本回合对其使用牌无距离与次数限制；3，你本回合不能对其使用牌。',
  ['$weiwan1'] = '繁花初成，所幸未晚于桑榆。',
  ['$weiwan2'] = '群胥泛舟，共载佳期若瑶梦。',
}

-- 主动技能
weiwan:addEffect('active', {
  anim_type = "offensive",
  prompt = "#weiwan-active",
  can_use = function(self, player)
    return player:usedSkillTimes(weiwan.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function (skill, player, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    return not player:prohibitDiscard(card) and card:getMark("qiqin") > 0
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local qin_suit = Fk:getCardById(effect.cards[1]).suit
    room:throwCard(effect.cards, weiwan.name, player, player)
    if player.dead or to.dead then return end
    local cardsMap = {}
    for _, id in ipairs(to:getCardIds("hej")) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit and suit ~= qin_suit then
        cardsMap[suit] = cardsMap[suit] or {}
        table.insert(cardsMap[suit], id)
      end
    end
    local get = {}
    for _, value in pairs(cardsMap) do
      table.insert(get, table.random(value))
    end
    if #get > 0 then
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonPrey, weiwan.name, nil, true, player.id)
      if to.dead then return end
      if #get == 1 then
        room:loseHp(to, 1, weiwan.name)
      elseif #get == 2 then
        room:addTableMark(player, "weiwan_targetmod-turn", to.id)
      elseif #get == 3 then
        room:addTableMark(player, "weiwan_prohibit-turn", to.id)
      end
    end
  end,
})

-- 触发技能（包含刷新）
weiwan:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    if player == target then
      local mark = player:getTableMark("weiwan_targetmod-turn")
      return #mark > 0 and table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return table.contains(mark, pid)
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

-- 目标修正技能
weiwan:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("weiwan_targetmod-turn"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and to and table.contains(player:getTableMark("weiwan_targetmod-turn"), to.id)
  end,
})

-- 禁用技能
weiwan:addEffect('prohibit', {
  is_prohibited = function(self, player, to, card)
    return table.contains(player:getTableMark("weiwan_prohibit-turn"), to.id)
  end,
})

return weiwan
