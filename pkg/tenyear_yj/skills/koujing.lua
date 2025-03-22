local koujing = fk.CreateSkill {
  name = "koujing",
}

Fk:loadTranslationTable{
  ["koujing"] = "寇旌",
  [":koujing"] = "出牌阶段开始时，你可以选择任意张手牌，这些牌本回合视为不计入次数的【杀】。其他角色受到以此法使用的【杀】的伤害后展示这些牌，"..
  "其可用所有手牌交换这些牌。",

  ["#koujing-invoke"] = "寇旌：你可以将任意张手牌作为“寇旌”牌，本回合视为不计入次数的【杀】",
  ["@@koujing-turn"] = "寇旌",
  ["#koujing-ask"] = "寇旌：是否用所有手牌交换 %src 的“寇旌”牌？",

  ["$koujing1"] = "驰马掠野，塞外称雄。",
  ["$koujing2"] = "控弦十万，纵横漠南。",
}

koujing:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(koujing.name) and player.phase == player.Play and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      skill_name = koujing.name,
      min_num = 1,
      max_num = player:getHandcardNum(),
      prompt = "#koujing-invoke",
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, id in ipairs(event:getCostData(self).cards) do
      player.room:setCardMark(Fk:getCardById(id), "@@koujing-turn", 1)
    end
    player:filterHandcards()
  end,
})
koujing:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, koujing.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

koujing:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("@@koujing-turn") > 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = koujing.name
    return c
  end,
})

koujing:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, koujing.name)
  end,
})

koujing:addEffect(fk.Damaged, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.from and data.from == player and target ~= player and not player.dead and
      data.card and table.contains(data.card.skillNames, koujing.name) and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@koujing-turn") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getMark("@@koujing-turn") > 0
    end)
    player:showCards(ids)
    if player.dead or target.dead or target:isKongcheng() then return end
    if room:askToSkillInvoke(target, {
      skill_name = "koujing",
      prompt = "#koujing-ask:"..player.id,
    }) then
      local cards1 = table.filter(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@koujing-turn") > 0
      end)
      local cards2 = table.simpleClone(target:getCardIds("h"))
      room:swapCards(player, {
        {player, cards1},
        {target, cards2},
      }, koujing.name)
    end
  end,
})

return koujing
