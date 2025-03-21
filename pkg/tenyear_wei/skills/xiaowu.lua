local xiaowu = fk.CreateSkill {
  name = "xiaowul",
}

Fk:loadTranslationTable{
  ["xiaowul"] = "骁武",
  [":xiaowul"] = "出牌阶段限一次，你可以弃置一张牌，从牌堆获得一张牌面信息包含【杀】的牌（以此法获得的牌不计次数）。当你造成伤害后，"..
  "此技能视为未发动过且本回合改为获得两张。",

  ["#xiaowul"] = "骁武：弃一张牌，获得%arg张描述包含【杀】的牌",
  ["@@xiaowul-inhand"] = "骁武",

  ["$xiaowul1"] = "百战生豪意，一戟破万军！",
  ["$xiaowul2"] = "烽烟既起，吾当独擎沙场！",
}

xiaowu:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player)
    local n = player:getMark("xiaowul-turn") > 0 and 2 or 1
    return "#xiaowul:::"..n
  end,
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(xiaowu.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().draw_pile, function (id)
        return string.find(Fk:translate(":"..Fk:getCardById(id).name, "zh_CN"), "【杀】") ~= nil
      end)
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, xiaowu.name, player, player)
    if player.dead then return end
    local cards = table.filter(room.draw_pile, function (id)
      return string.find(Fk:translate(":" .. Fk:getCardById(id).name, "zh_CN"), "【杀】") ~= nil
    end)
    if #cards > 0 then
      local n = player:getMark("xiaowul-turn") > 0 and 2 or 1
      room:moveCardTo(table.random(cards, n), Card.PlayerHand, player, fk.ReasonJustMove, xiaowu.name, nil, false, player,
        "@@xiaowul-inhand")
    end
  end,
})
xiaowu:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and
    table.every(Card:getIdList(data.card), function (id)
      return Fk:getCardById(id):getMark("@@xiaowul-inhand") > 0
    end)
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end,
})
xiaowu:addEffect(fk.Damage, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(xiaowu.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    player:setSkillUseHistory(xiaowu.name, 0, Player.HistoryPhase)
    player.room:setPlayerMark(player, "xiaowul-turn", 1)
  end,
})
xiaowu:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and
      table.every(Card:getIdList(card), function (id)
        return Fk:getCardById(id):getMark("@@xiaowul-inhand") > 0
      end)
  end,
})

return xiaowu
