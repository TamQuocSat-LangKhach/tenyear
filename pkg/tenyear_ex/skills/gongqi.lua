local gongqi = fk.CreateSkill {
  name = "ty_ex__gongqi",
}

Fk:loadTranslationTable{
  ["ty_ex__gongqi"] = "弓骑",
  [":ty_ex__gongqi"] = "出牌阶段限一次，你可以弃置一张牌，此回合你的攻击范围无限，使用此花色的【杀】无次数限制。若弃置的牌为装备牌，"..
  "你可以弃置一名其他角色的一张牌。",

  ["#ty_ex__gongqi"] = "弓骑：弃一张牌，本回合攻击范围无限且此花色【杀】无次数限制；若弃置装备牌，可以弃置一名其他角色的一张牌",
  ["@ty_ex__gongqi-turn"] = "弓骑",
  ["#ty_ex__gongqi-choose"] = "弓骑：你可以弃置一名其他角色的一张牌",

  ["$ty_ex__gongqi1"] = "马踏飞箭，弓骑无双！",
  ["$ty_ex__gongqi2"] = "提弓上马，箭砺八方！"
}

gongqi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty_ex__gongqi",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(gongqi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local suit = Fk:getCardById(effect.cards[1]):getSuitString(true)
    if suit ~= "log_nosuit" then
      room:addTableMarkIfNeed(player, "@ty_ex__gongqi-turn", suit)
    end
    room:throwCard(effect.cards, gongqi.name, player, player)
    if player.dead then return end
    if Fk:getCardById(effect.cards[1]).type == Card.TypeEquip then
      local targets = table.filter(room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        skill_name = gongqi.name,
        min_num = 1,
        max_num = 1,
        targets = targets,
        prompt = "#ty_ex__gongqi-choose",
        cancelable = true,
      })
      if #to > 0 then
        local id = room:askToChooseCard(player, {
          target = to[1],
          flag = "he",
          skill_name = gongqi.name,
        })
        room:throwCard(id, gongqi.name, to[1], player)
      end
    end
  end,
})

gongqi:addEffect("atkrange", {
  correct_func = function (skill, from, to)
    if from:usedSkillTimes(gongqi.name, Player.HistoryTurn) > 0 then
      return 999
    end
  end,
})

gongqi:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and
      table.contains(player:getTableMark("@ty_ex__gongqi-turn"), data.card:getSuitString(true))
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

gongqi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return skill.trueName == "slash_skill" and card and
      table.contains(player:getTableMark("@ty_ex__gongqi-turn"), card:getSuitString(true))
  end,
})

return gongqi
