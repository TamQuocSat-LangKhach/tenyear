local chengyan = fk.CreateSkill {
  name = "chengyan",
}

Fk:loadTranslationTable{
  ["chengyan"] = "乘烟",
  [":chengyan"] = "当你使用【杀】或普通锦囊牌指定其他角色为目标后，你可以摸一张牌并展示之，若为【杀】或普通锦囊牌且可以对目标使用，"..
  "将你使用的牌的效果改为展示牌的效果，否则将展示牌标记为“笛”。",

  ["#chengyan-invoke"] = "乘烟：是否摸一张牌？若是【杀】或普通锦囊牌，则将此%arg改为摸到牌的效果",

  ["$chengyan1"] = "",
  ["$chengyan2"] = "",
}

chengyan:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengyan.name) and data.firstTarget and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      not table.contains(data.tos, player)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chengyan.name,
      prompt = "#chengyan-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(1)
    if #cards == 0 or player.dead or not table.contains(player:getCardIds("h"), cards[1]) then return end
    room:showCards(cards, player)
    if player.dead then return end
    local card = Fk:getCardById(cards[1])
    if (card.trueName == "slash" or card:isCommonTrick()) and
      not card.is_passive and card.name ~= data.card.name and
      table.find(data.tos, function (p)
        return card.skill:modTargetFilter(player, p, data.tos, card, {bypass_distances = true})
      end) then
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event ~= nil then
        local new_card = Fk:cloneCard(data.card.name, data.card.suit, data.card.number)
        for k, v in pairs(data.card) do
          if new_card[k] == nil then
            new_card[k] = v
          end
        end
        if data.card:isVirtual() then
          new_card.subcards = data.card.subcards
        else
          new_card.id = data.card.id
        end
        new_card.skillNames = data.card.skillNames
        new_card.skill = card.skill
        data.card = new_card
        use_event.data.card = new_card
        local useCardIds = new_card:isVirtual() and new_card.subcards or { new_card.id }
        if #useCardIds > 0 then
          room:sendCardVirtName(useCardIds, card.name)
        end
      end
      return
    elseif table.contains(player:getCardIds("h"), cards[1]) and player:hasSkill("xidi", true) then
      room:setCardMark(card, "@@xidi-inhand", 1)
    end
  end,
})

return chengyan
