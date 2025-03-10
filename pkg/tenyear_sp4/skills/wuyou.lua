local wuyou = fk.CreateSkill {
  name = "wuyou"
}

Fk:loadTranslationTable{
  ['wuyou'] = '武佑',
  ['wuyou&'] = '武佑',
  ['#wuyou-active'] = '发动 武佑，令一张手牌视为你声明的牌（五选一）',
  ['wuyou_declare'] = '武佑',
  ['#wuyou-declare'] = '武佑：将一张手牌交给%dest并令此牌视为声明的牌名',
  ['@@wuyou-inhand'] = '武佑',
  ['#wuyou_filter'] = '武佑',
  [':wuyou'] = '出牌阶段限一次，你可以从五个随机的不为装备牌的牌名中声明一个并选择你的一张手牌，此牌视为你声明的牌且使用时无距离和次数限制。其他角色的出牌阶段限一次，其可以将一张手牌交给你，然后你可以从五个随机的不为装备牌的牌名中声明一个并将一张手牌交给该角色，此牌视为你声明的牌且使用时无距离和次数限制。',
  ['$wuyou1'] = '秉赤面，观春秋，虓菟踏纛，汗青著峥嵘！',
  ['$wuyou2'] = '着青袍，饮温酒，五关已过，来将且通名！',
}

wuyou:addEffect("active", {
  attached_skill_name = "wuyou&",
  prompt = "#wuyou-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(wuyou.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = effect.tos and #effect.tos > 0 and room:getPlayerById(effect.tos[1]) or player
    local card_names = player:getMark("wuyou_names")
    if type(card_names) ~= "table" then
      card_names = {}
      local tmp_names = {}
      local card, index
      for _, id in ipairs(Fk:getAllCardIds()) do
        card = Fk:getCardById(id, true)
        if not card.is_derived and card.type ~= Card.TypeEquip then
          index = table.indexOf(tmp_names, card.trueName)
          if index == -1 then
            table.insert(tmp_names, card.trueName)
            table.insert(card_names, {card.name})
          else
            table.insertIfNeed(card_names[index], card.name)
          end
        end
      end
      room:setPlayerMark(player, "wuyou_names", card_names)
    end
    if #card_names == 0 then return end
    card_names = table.map(table.random(card_names, 5), function (card_list)
      return table.random(card_list)
    end)
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "wuyou_declare",
      prompt = "#wuyou-declare::" .. target.id,
      cancelable = true,
      extra_data = { interaction_choices = card_names },
    })
    if not success then return end
    local id = dat.cards[1]
    local card_name = dat.interaction
    if target == player then
      room:setCardMark(Fk:getCardById(id), "@@wuyou-inhand", card_name)
    else
      room:moveCardTo(id, Player.Hand, target, fk.ReasonGive, wuyou.name, nil, false, player.id, {"@@wuyou-inhand", card_name})
    end
  end,
})

wuyou:addEffect("filter", {
  name = "#wuyou_filter",
  mute = true,
  card_filter = function(self, player, card, isJudgeEvent)
    return card:getMark("@@wuyou-inhand") ~= 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard(card:getMark("@@wuyou-inhand"), card.suit, card.number)
  end,
})

wuyou:addEffect("targetmod", {
  name = "#wuyou_targetmod",
  bypass_times = function(self, player, skill_name, scope, card, to)
    return card and not card:isVirtual() and card:getMark("@@wuyou-inhand") ~= 0
  end,
  bypass_distances =  function(skill, player, skill_name, card, to)
    return card and not card:isVirtual() and card:getMark("@@wuyou-inhand") ~= 0
  end,
})

wuyou:addEffect(fk.PreCardUse, {
  name = "#wuyou_refresh",
  can_trigger = function(self, event, target, player, data)
    return target == player and not data.card:isVirtual() and data.card:getMark("@@wuyou-inhand") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

return wuyou
