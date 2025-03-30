local jingyin = fk.CreateSkill {
  name = "jingyin",
}

Fk:loadTranslationTable{
  ["jingyin"] = "经音",
  [":jingyin"] = "每回合限一次，当一名角色于其回合外使用的【杀】进入弃牌堆后，你可以令除其以外的一名角色获得之，且使用时无次数限制。",

  ["#jingyin-card"] = "经音：你可以令一名角色获得%arg，使用时无次数限制",
  ["@@jingyin-inhand"] = "经音",

  ["$jingyin1"] = "金柝越关山，唯送君于南。",
  ["$jingyin2"] = "燕燕于飞，寒江照孤影。",
}

jingyin:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jingyin.name) and player:usedSkillTimes(jingyin.name, Player.HistoryTurn) == 0 then
      local room = player.room
      local move_event = room.logic:getCurrentEvent()
      local use_event = move_event.parent
      if use_event ~= nil and use_event.event == GameEvent.UseCard then
        local use = use_event.data
        if use.from ~= room.current and use.card.trueName == "slash" then
          local card_ids = table.simpleClone(Card:getIdList(use.card))
          if #card_ids == 0 then return false end
          for _, move in ipairs(data) do
            if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonUse then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.Processing and table.contains(room.discard_pile, info.cardId) then
                  if not table.removeOne(card_ids, info.cardId) then
                    return false
                  end
                end
              end
            end
          end
          if #card_ids == 0 then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, false)
    if use_event == nil then return false end
    local use = use_event.data
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(use.from, false),
      min_num = 1,
      max_num = 1,
      skill_name = jingyin.name,
      prompt = "#jingyin-card:::"..use.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to, cards = Card:getIdList(use.card)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, jingyin.name, nil, true, player, "@@jingyin-inhand")
  end,
})

jingyin:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card:getMark("@@jingyin-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

jingyin:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and card:getMark("@@jingyin-inhand") > 0
  end,
})

return jingyin
