local chongyi = fk.CreateSkill {
  name = "chongyi"
}

Fk:loadTranslationTable{
  ['chongyi'] = '崇义',
  ['#chongyi-draw'] = '崇义：你可以令 %dest 摸两张牌且此阶段使用【杀】次数上限+1',
  ['#chongyi-maxcards'] = '崇义：你可以令 %dest 本回合手牌上限+1',
  [':chongyi'] = '一名角色于出牌阶段内使用的第一张牌若为【杀】，你可令其摸两张牌且于此阶段使用【杀】的次数上限+1；一名角色的出牌阶段结束时，若其于此阶段使用过的最后一张牌为【杀】，你可令其于此回合内手牌上限+1，然后你获得弃牌堆中的此【杀】。',
  ['$chongyi1'] = '班虽卑微，亦知何为大义。',
  ['$chongyi2'] = '大义当头，且助君一臂之力。',
}

chongyi:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chongyi.name) and target.phase == Player.Play and not target.dead then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local x = target:getMark("chongyi_record-turn")
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if use.from == target.id then
            x = e.id
            room:setPlayerMark(target, "chongyi_record-turn", x)
            return true
          end
        end, Player.HistoryPhase)
      end
      return x == use_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#chongyi-draw::"
    local room = player.room
    if room:askToSkillInvoke(player, {skill_name=chongyi.name, prompt=prompt .. target.id}) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      target:drawCards(2, chongyi.name)
      room:addPlayerMark(target, MarkEnum.SlashResidue .. "-phase")
    end
  end,
})

chongyi:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chongyi.name) and target.phase == Player.Play and not target.dead then
      local logic = player.room.logic
      local phase_event = logic:getCurrentEvent():findParent(GameEvent.Phase, true)
      if phase_event == nil then return false end
      local use_events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      for i = #use_events, 1, -1 do
        if use_events[i].id < phase_event.id then return false end
        local use = use_events[i].data[1]
        if use.from == target.id then
          if use.card.trueName == "slash" then
            event:setCostData(self, Card:getIdList(use.card))
            return true
          else
            return false
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#chongyi-maxcards::"
    local room = player.room
    if room:askToSkillInvoke(player, {skill_name=chongyi.name, prompt=prompt .. target.id}) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 1)
      local cards = table.filter(event:getCostData(self), function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards > 0 then
        room:obtainCard(player, cards, true)
      end
    end
  end,
})

return chongyi
