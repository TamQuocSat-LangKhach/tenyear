local koujing = fk.CreateSkill {
  name = "koujing"
}

Fk:loadTranslationTable{
  ['koujing'] = '寇旌',
  ['#koujing-invoke'] = '寇旌：你可以将任意张手牌作为“寇旌”牌，本回合视为不计入次数的【杀】',
  ['@@koujing-inhand'] = '寇旌',
  ['#koujing_filter'] = '寇旌',
  ['#koujing-card'] = '寇旌：你可以用所有手牌交换 %src 这些“寇旌”牌',
  [':koujing'] = '出牌阶段开始时，你可以选择任意张手牌，这些牌本回合视为不计入次数的【杀】。其他角色受到以此法使用的【杀】的伤害后展示这些牌，其可用所有手牌交换这些牌。',
  ['$koujing1'] = '驰马掠野，塞外称雄。',
  ['$koujing2'] = '控弦十万，纵横漠南。',
}

-- 主技能触发
koujing:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(koujing.name) and player.phase == player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = player:getHandcardNum(),
      pattern = ".",
      prompt = "#koujing-invoke"
    })
    if #cards > 0 then
      event:setCostData(self, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, id in ipairs(event:getCostData(self)) do
      player.room:setCardMark(Fk:getCardById(id), "@@koujing-inhand", 1)
    end
    player:filterHandcards()
  end,

  can_refresh = function (self, event, target, player, data)
    if event == fk.AfterTurnEnd then
      return target == player and table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@koujing-inhand") > 0 end)
    else
      return target == player and table.contains(data.card.skillNames, "koujing")
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterTurnEnd then
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        player.room:setCardMark(Fk:getCardById(id), "@@koujing-inhand", 0)
      end
      player:filterHandcards()
    else
      data.extraUse = true
    end
  end,
})

-- 过滤技能
koujing:addEffect('filter', {
  card_filter = function(self, player, card)
    return card:getMark("@@koujing-inhand") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, player, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = "koujing"
    return c
  end,
})

-- 目标修正技能
koujing:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, "koujing")
  end,
})

-- 触发技
koujing:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if data.from and data.from == player and target ~= player and not player.dead and
      data.card and table.contains(data.card.skillNames, "koujing") then
      return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@koujing-inhand") > 0 end)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@koujing-inhand") > 0 end)
    player:showCards(ids)
    if player.dead or target.dead or target:isKongcheng() then return end
    room:doIndicate(player.id, {target.id})
    local params = {
      skill_name = "koujing",
      prompt = "#koujing-card:" .. player.id,
    }
    if room:askToSkillInvoke(target, params) then
      local cards2 = table.simpleClone(target:getCardIds("h"))
      local cards1 = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@koujing-inhand") > 0 end)
      U.swapCards(room, player, player, target, cards1, cards2, "koujing")
    end
  end,
})

return koujing
