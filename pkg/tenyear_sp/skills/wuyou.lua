local wuyou = fk.CreateSkill {
  name = "wuyou",
  attached_skill_name = "wuyou&",
}

Fk:loadTranslationTable{
  ["wuyou"] = "武佑",
  [":wuyou"] = "每名角色的出牌阶段限一次，其可以交给你一张手牌，然后你可以从五个随机非装备牌名中选择一个并交给其一张手牌，"..
  "此牌视为你选择的牌名且无距离次数限制。（若为你则跳过交给手牌）",

  ["#wuyou"] = "武佑：从五个随机牌名中选择，令一张手牌视为你声明的牌",
  ["#wuyou-declare"] = "武佑：将一张手牌交给 %dest 并令此牌视为声明的牌名",
  ["@@wuyou-inhand"] = "武佑",

  ["$wuyou1"] = "秉赤面，观春秋，虓菟踏纛，汗青著峥嵘！",
  ["$wuyou2"] = "着青袍，饮温酒，五关已过，来将且通名！",
}

wuyou:addEffect("active", {
  prompt = "#wuyou",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(wuyou.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = player
    if #effect.tos > 0 then
      target = effect.tos[1]
    end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "wuyou_declare",
      prompt = "#wuyou-declare::"..target.id,
      cancelable = true,
    })
    if not (success and dat) then return end
    local id = dat.cards[1]
    local card_name = dat.interaction
    if target == player then
      room:setCardMark(Fk:getCardById(id), "@@wuyou-inhand", card_name)
    else
      room:moveCardTo(id, Player.Hand, target, fk.ReasonGive, wuyou.name, nil, false, player, {"@@wuyou-inhand", card_name})
    end
  end,
})

wuyou:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return card:getMark("@@wuyou-inhand") ~= 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard(card:getMark("@@wuyou-inhand"), card.suit, card.number)
  end,
})

wuyou:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@wuyou-inhand") ~= 0
  end,
  bypass_distances =  function(skill, player, skill, card, to)
    return card and card:getMark("@@wuyou-inhand") ~= 0
  end,
})

wuyou:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and not data.card:isVirtual() and data.card:getMark("@@wuyou-inhand") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

return wuyou
