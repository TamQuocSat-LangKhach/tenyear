local zhaowen = fk.CreateSkill {
  name = "zhaowen"
}

Fk:loadTranslationTable{
  ['zhaowen'] = '昭文',
  ['#zhaowen'] = '昭文：将一张黑色“昭文”牌当任意普通锦囊牌使用（每回合每种牌名限一次）',
  ['@@zhaowen-turn'] = '昭文',
  ['#zhaowen_trigger'] = '昭文',
  ['#zhaowen-invoke'] = '昭文：你可以展示手牌，本回合其中黑色牌可以当任意锦囊牌使用，红色牌使用时摸一张牌',
  [':zhaowen'] = '出牌阶段开始时，你可以展示所有手牌。若如此做，本回合其中的黑色牌可以当任意一张普通锦囊牌使用（每回合每种牌名限一次），其中的红色牌你使用时摸一张牌。',
  ['$zhaowen1'] = '我辈昭昭，正始之音浩荡。',
  ['$zhaowen2'] = '正文之昭，微言之绪，绝而复续。',
}

zhaowen:addEffect("viewas", {
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#zhaowen",
  interaction = function()
    local all_names = U.getAllCardNames("t")
    local names = U.getViewAsCardNames(Self, zhaowen.name, all_names, {}, Self:getTableMark(zhaowen.name .. "-turn"))
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.color == Card.Black and card:getMark("@" .. zhaowen.name .. "-turn") > 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = zhaowen.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark(zhaowen.name .. "-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, zhaowen.name .. "-turn", mark)
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(zhaowen.name, Player.HistoryTurn) > 0 and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@" .. zhaowen.name .. "-turn") > 0 end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes(zhaowen.name, Player.HistoryTurn) > 0 and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@" .. zhaowen.name .. "-turn") > 0 end)
  end,
})

zhaowen:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhaowen.name) and player.phase == Player.Play
      and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = zhaowen.name, prompt = "#zhaowen-invoke" })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhaowen.name)
    room:notifySkillInvoked(player, zhaowen.name, "special")
    local cards = table.simpleClone(player:getCardIds("h"))
    player:showCards(cards)
    if not player.dead and not player:isKongcheng() then
      room:setPlayerMark(player, zhaowen.name .. "-turn", cards)
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id, true), "@" .. zhaowen.name .. "-turn", 1)
      end
    end
  end,
})

zhaowen:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhaowen.name) and player.phase == Player.Play
      and data.card.color == Card.Red and not data.card:isVirtual() and data.card:getMark("@" .. zhaowen.name .. "-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhaowen.name)
    room:notifySkillInvoked(player, zhaowen.name, "drawcard")
    player:drawCards(1, zhaowen.name)
  end,
})

zhaowen:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark(zhaowen.name .. "-turn") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark(zhaowen.name .. "-turn")
    for _, move in ipairs(data) do
      if move.toArea ~= Card.Processing then
        for _, info in ipairs(move.moveInfo) do
          table.removeOne(mark, info.cardId)
          room:setCardMark(Fk:getCardById(info.cardId), "@" .. zhaowen.name .. "-turn", 0)
        end
      end
    end
    room:setPlayerMark(player, zhaowen.name .. "-turn", mark)
  end,
})

zhaowen:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark(zhaowen.name .. "-turn") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getMark(zhaowen.name .. "-turn")) do
      room:setCardMark(Fk:getCardById(id), "@" .. zhaowen.name .. "-turn", 0)
    end
  end,
})

return zhaowen
