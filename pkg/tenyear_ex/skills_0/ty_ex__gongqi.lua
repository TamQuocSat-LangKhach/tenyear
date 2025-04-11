local ty_ex__gongqi = fk.CreateSkill {
  name = "ty_ex__gongqi"
}

Fk:loadTranslationTable{
  ['ty_ex__gongqi'] = '弓骑',
  ['@ty_ex__gongqi-turn'] = '弓骑',
  ['#ty_ex__gongqi-choose'] = '弓骑：你可以弃置一名其他角色的一张牌',
  [':ty_ex__gongqi'] = '出牌阶段限一次，你可以弃置一张牌，此回合你的攻击范围无限，且使用此花色的【杀】无次数限制。若你以此法弃置的牌为装备牌，你可以弃置一名其他角色的一张牌。',
  ['$ty_ex__gongqi1'] = '马踏飞箭，弓骑无双！',
  ['$ty_ex__gongqi2'] = '提弓上马，箭砺八方！'
}

ty_ex__gongqi:addEffect('active', {
  anim_type = "offensive",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__gongqi.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:addPlayerMark(player, "ty_ex__gongqi-turn", 999)
    room:setPlayerMark(player, "@ty_ex__gongqi-turn", Fk:getCardById(effect.cards[1]):getSuitString(true))
    room:throwCard(effect.cards, ty_ex__gongqi.name, player, player)
    if Fk:getCardById(effect.cards[1]).type == Card.TypeEquip then
      local to = room:askToChoosePlayers(player, {
        targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#ty_ex__gongqi-choose",
        skill_name = ty_ex__gongqi.name
      })
      if #to > 0 then
        local target = room:getPlayerById(to[1])
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = ty_ex__gongqi.name
        })
        room:throwCard({id}, ty_ex__gongqi.name, target, player)
      end
    end
  end,
})

ty_ex__gongqi:addEffect('refresh', {
  events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player == target and data.card.trueName == "slash" and not data.card:isVirtual() and
      data.card:getSuitString(true) == player:getMark("@ty_ex__gongqi-turn")
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

ty_ex__gongqi:addEffect('atkrange', {
  correct_func = function (skill, from, to)
    return from:getMark("ty_ex__gongqi-turn")
  end,
})

ty_ex__gongqi:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return player:getMark("@ty_ex__gongqi-turn") ~= 0 and scope == Player.HistoryPhase and card and card.trueName == "slash" and
      player:getMark("@ty_ex__gongqi-turn") == card:getSuitString(true)
  end,
})

return ty_ex__gongqi
