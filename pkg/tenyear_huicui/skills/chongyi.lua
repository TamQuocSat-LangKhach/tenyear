local chongyi = fk.CreateSkill {
  name = "chongyi",
}

Fk:loadTranslationTable{
  ["chongyi"] = "崇义",
  [":chongyi"] = "一名角色于出牌阶段内使用的第一张牌若为【杀】，你可以令其摸两张牌且此阶段使用【杀】次数上限+1；一名角色的出牌阶段结束时，"..
  "若其于此阶段使用的最后一张牌为【杀】，你可以令其此回合手牌上限+1，然后你获得弃牌堆中的此【杀】。",

  ["#chongyi-draw"] = "崇义：你可以令 %dest 摸两张牌且此阶段使用【杀】次数上限+1",
  ["#chongyi-maxcards"] = "崇义：你可以令 %dest 本回合手牌上限+1，你获得其使用的【杀】",

  ["$chongyi1"] = "班虽卑微，亦知何为大义。",
  ["$chongyi2"] = "大义当头，且助君一臂之力。",
}

chongyi:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chongyi.name) and target.phase == Player.Play and not target.dead and
      data.card.trueName == "slash" then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return end
      local x = target:getMark("chongyi_record-phase")
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data
          if use.from == target then
            x = e.id
            room:setPlayerMark(target, "chongyi_record-phase", x)
            return true
          end
        end, Player.HistoryPhase)
      end
      return x == use_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = chongyi.name,
      prompt = "#chongyi-draw::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, MarkEnum.SlashResidue .. "-phase")
    target:drawCards(2, chongyi.name)
  end,
})

chongyi:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chongyi.name) and target.phase == Player.Play and not target.dead then
      local use_event = player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        return e.data.from == target
      end, nil, Player.HistoryPhase)
      return #use_event > 0 and use_event[1].data.card.trueName == "slash"
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = chongyi.name,
      prompt = "#chongyi-maxcards::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 1)
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == target then
        if room:getCardArea(use.card) == Card.DiscardPile then
          room:obtainCard(player, use.card, true, fk.ReasonJustMove, player, chongyi.name)
        end
        return true
      end
    end, nil, Player.HistoryPhase)
  end,
})

return chongyi
