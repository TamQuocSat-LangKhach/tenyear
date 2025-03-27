local bijing = fk.CreateSkill {
  name = "bijing"
}

Fk:loadTranslationTable{
  ['bijing'] = '闭境',
  ['#bijing-invoke'] = '闭境：你可以将至多两张手牌标记为“闭境”牌',
  ['@@bijing'] = '闭境',
  [':bijing'] = '结束阶段，你可以选择至多两张手牌标记为“闭境”。若你于回合外失去“闭境”牌，当前回合角色的弃牌阶段开始时，其需弃置两张牌。准备阶段，你重铸手牌中的“闭境”牌。',
  ['$bijing1'] = '拒吴闭境，臣誓保永昌！',
  ['$bijing2'] = '一臣无二主，可战不可降！',
}

bijing:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bijing.name) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = 2,
      include_equip = false,
      skill_name = bijing.name,
      cancelable = true,
      prompt = "#bijing-invoke"
    })
    if #cards > 0 then
      event:setCostData(skill, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cards = event:getCostData(skill)
    for _, id in ipairs(cards) do
      player.room:setCardMark(Fk:getCardById(id), "@@bijing", 1)
    end
  end,
})

bijing:addEffect(fk.AfterCardsMove, {
  global = false,
  can_refresh = function(self, event, target, player, data)
    if player.phase == Player.NotActive then
      for _, move in ipairs(data) do
        if move.from and move.from == player.id then
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
      if move.from and move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          room:setCardMark(Fk:getCardById(info.cardId), "@@bijing", 0)
        end
      end
    end
    if room.current and not room.current.dead then
      room:setPlayerMark(room.current, "bijing_invoking-turn", player.id)
    end
  end,
})

bijing:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if player.phase == Player.Discard then
        return player:getMark("bijing_invoking-turn") ~= 0 and not player:isNude()
      elseif player.phase == Player.Start then
        return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@bijing") > 0 end)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Discard then
      local src = room:getPlayerById(player:getMark("bijing_invoking-turn"))
      src:broadcastSkillInvoke(bijing.name)
      room:notifySkillInvoked(src, bijing.name, "control")
      room:doIndicate(src.id, {player.id})
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = bijing.name,
        cancelable = false
      })
    else
      player:broadcastSkillInvoke(bijing.name)
      room:notifySkillInvoked(player, bijing.name, "drawcard")
      local cards = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@bijing") > 0 end)
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@bijing", 0)
      end
      room:recastCard(cards, player, bijing.name)
    end
  end,
})

return bijing
