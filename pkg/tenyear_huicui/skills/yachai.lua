local yachai = fk.CreateSkill {
  name = "yachai",
}

Fk:loadTranslationTable{
  ["yachai"] = "崖柴",
  [":yachai"] = "当你受到伤害后，你可以令伤害来源选择一项：1.弃置一半手牌（向上取整）；2.其本回合不能再使用手牌，你摸两张牌；"..
  "3.展示所有手牌，然后交给你一种花色的所有手牌。",

  ["#yachai-invoke"] = "崖柴：是否对 %dest 发动“崖柴”？",
  ["yachai1"] = "弃置一半手牌",
  ["yachai2"] = "你本回合不能使用手牌，%src摸两张牌",
  ["yachai3"] = "展示所有手牌，交给%src一种花色的所有手牌",
  ["#yachai-choice"] = "崖柴：选择 %src 令你执行的一项",
  ["@@yachai-turn"] = "崖柴",
  ["#yachai-give"] = "崖柴：选择交给 %src 的花色",

  ["$yachai1"] = "才秀知名，无所顾惮。",
  ["$yachai2"] = "讲论经义，为万世法。",
}

yachai:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yachai.name) and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yachai.name,
      prompt = "#yachai-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"yachai2:"..player.id}
    if not data.from:isKongcheng() then
      table.insert(choices, 2, "yachai3:"..player.id)
      if #table.filter(data.from:getCardIds(), function(id)
        return not data.from:prohibitDiscard(id)
      end) >= ((data.from:getHandcardNum() + 1) // 2) then
        table.insert(choices, 1, "yachai1")
      end
    end
    local choice = room:askToChoice(data.from, {
      choices = choices,
      skill_name = yachai.name,
      prompt = "#yachai-choice:"..player.id,
      all_choices = {"yachai1", "yachai2:"..player.id, "yachai3:"..player.id}
    })
    if choice == "yachai1" then
      local n = (data.from:getHandcardNum() + 1) // 2
      room:askToDiscard(data.from, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = yachai.name,
        cancelable = false,
      })
    elseif choice:startsWith("yachai2") then
      room:setPlayerMark(data.from, "@@yachai-turn", 1)
      player:drawCards(2, yachai.name)
    elseif choice == "yachai3" then
      data.from:showCards(data.from:getCardIds("h"))
      if player.dead or data.from.dead or data.from:isKongcheng() then return end
      local suits = {}
      for _, id in ipairs(data.from:getCardIds("h")) do
        table.insertIfNeed(suits, Fk:getCardById(id):getSuitString(true))
      end
      table.removeOne(suits, "log_nosuit")
      if #suits == 0 then return end
      choice = room:askToChoice(data.from, {
        choices = suits,
        skill_name = yachai.name,
        prompt = "#yachai-give:"..player.id,
      })
      local cards = table.filter(data.from:getCardIds("h"), function(id)
        return Fk:getCardById(id):getSuitString(true) == choice
      end)
      room:obtainCard(player, cards, true, fk.ReasonGive, data.from, yachai.name)
    end
  end,
})

yachai:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("@@yachai-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and
        table.every(subcards, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
})

return yachai
