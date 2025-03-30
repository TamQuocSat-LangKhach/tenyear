local chixing = fk.CreateSkill {
  name = "chixing",
}

Fk:loadTranslationTable{
  ["chixing"] = "迟行",
  [":chixing"] = "一名角色的出牌阶段结束时，若此阶段有【杀】进入弃牌堆，你可以摸等量的牌，然后你可以使用摸到的一张【杀】。",

  ["#chixing-use"] = "迟行：你可以使用其中一张【杀】",

  ["$chixing1"] = "孤鸿鸣晚林，泪垂大江流。",
  ["$chixing2"] = "若路的尽头是离别，妾宁愿蹒跚一世。",
}

chixing:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chixing.name) and target.phase == Player.Play then
      local room = player.room
      local n = 0
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId, true).trueName == "slash" then
                n = n + 1
              end
            end
          end
        end
      end, Player.HistoryPhase)
      if n > 0 then
        event:setCostData(self, {choice = n})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:drawCards(player, event:getCostData(self).choice, chixing.name)
    if player.dead then return end
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id) and Fk:getCardById(id).trueName == "slash"
    end)
    room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = chixing.name,
      prompt = "#chixing-use",
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      cancelable = true,
    })
  end,
})

return chixing
