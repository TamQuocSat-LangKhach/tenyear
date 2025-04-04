local bijing = fk.CreateSkill {
  name = "bijing",
}

Fk:loadTranslationTable{
  ["bijing"] = "闭境",
  [":bijing"] = "结束阶段，你可以选择至多两张手牌标记为“闭境”。若你于回合外失去“闭境”牌，当前回合角色的弃牌阶段开始时，其需弃置两张牌。"..
  "准备阶段，你重铸手牌中的“闭境”牌。",

  ["#bijing-invoke"] = "闭境：你可以将至多两张手牌标记为“闭境”牌",
  ["@@bijing"] = "闭境",

  ["$bijing1"] = "拒吴闭境，臣誓保永昌！",
  ["$bijing2"] = "一臣无二主，可战不可降！",
}

bijing:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bijing.name) and player.phase == Player.Finish and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 2,
      include_equip = false,
      skill_name = bijing.name,
      cancelable = true,
      prompt = "#bijing-invoke",
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@bijing", 1)
    end
  end,
})

bijing:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Discard and not target.dead and
      table.contains(target:getTableMark("bijing_invoking-turn"), player.id) and not target:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(target, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = bijing.name,
      cancelable = false,
    })
  end,
})

bijing:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player.room.current ~= player then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@bijing") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          room:setCardMark(Fk:getCardById(info.cardId), "@@bijing", 0)
        end
      end
    end
    if not room.current.dead then
      room:addTableMark(room.current, "bijing_invoking-turn", player.id)
    end
  end,
})

bijing:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@bijing") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getMark("@@bijing") > 0
    end)
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@bijing", 0)
    end
    room:recastCard(cards, player, bijing.name)
  end,
})

return bijing
