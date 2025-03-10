local chixing = fk.CreateSkill {
  name = "chixing"
}

Fk:loadTranslationTable{
  ['chixing'] = '迟行',
  ['#chixing-use'] = '迟行：你可以使用一张【杀】',
  [':chixing'] = '一名角色的出牌阶段结束时，若有【杀】于此阶段内移至过弃牌堆，你可以摸等量的牌，然后你可以使用你摸到的这些牌中的一张【杀】。',
  ['$chixing1'] = '孤鸿鸣晚林，泪垂大江流。',
  ['$chixing2'] = '若路的尽头是离别，妾宁愿蹒跚一世。',
}

chixing:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if player:hasSkill(chixing.name) and target.phase == Player.Play then
      local room = player.room
      local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
      if phase_event == nil then return false end
      local x = 0
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId, true).trueName == "slash" then
                x = x + 1
              end
            end
          end
        end
        return false
      end, phase_event.id)
      if x > 0 then
        event:setCostData(skill, x)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = room:drawCards(player, event:getCostData(skill), chixing.name)
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id) and Fk:getCardById(id).trueName == "slash"
    end)
    if #cards > 0 then
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
    end
  end,
})

return chixing
