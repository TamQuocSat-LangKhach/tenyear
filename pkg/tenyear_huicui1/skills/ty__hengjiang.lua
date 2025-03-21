local ty__hengjiang = fk.CreateSkill {
  name = "ty__hengjiang"
}

Fk:loadTranslationTable{
  ['ty__hengjiang'] = '横江',
  ['#ty__hengjiang-invoke'] = '横江：是否令 %dest 本回合手牌上限-1？',
  [':ty__hengjiang'] = '当你受到1点伤害后，你可以令当前回合角色本回合手牌上限-1，此回合结束时，若其本回合弃牌阶段：没有弃置牌，你摸X张牌（X为本回合你发动此技能次数）；弃置过牌，你摸一张牌。',
  ['$ty__hengjiang1'] = '霸必奋勇杀敌，一雪夷陵之耻！',
  ['$ty__hengjiang2'] = '江横索寒，阻敌绝境之中！',
}

ty__hengjiang:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty__hengjiang.name) then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      return not turn_event.data[1].dead
    end
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then return end
    for i = 1, data.damage do
      if i > 1 and (self.cancel_cost or turn_event.data[1].dead or not player:hasSkill(ty__hengjiang.name)) then break end
      self:doCost(event, turn_event.data[1], player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {skill_name = ty__hengjiang.name, prompt = "#ty__hengjiang-invoke::"..target.id}) then
      event:setCostData(self, {tos = {target.id}})
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(target, "@hengjiang-turn", 1)
    room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 1)
  end
})

ty__hengjiang:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes(ty__hengjiang.name, Player.HistoryTurn) > 0 and not player.dead
  end,
  on_trigger = function(self, event, target, player, data)
    local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    self:doCost(event, turn_event.data[1], player)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local phase_ids = {}
    room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
      if e.data[2] == Player.Discard then
        table.insert(phase_ids, {e.id, e.end_id})
      end
      return false
    end, Player.HistoryTurn)
    if #phase_ids > 0 then
      if #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        local in_discard = false
        for _, ids in ipairs(phase_ids) do
          if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
            in_discard = true
            break
          end
        end
        if in_discard then
          for _, move in ipairs(e.data) do
            if move.from == target.id and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  return true
                end
              end
            end
          end
        end
        return false
      end, Player.HistoryTurn) > 0 then
        player:drawCards(1, ty__hengjiang.name)
      else
        player:drawCards(player:usedSkillTimes(ty__hengjiang.name, Player.HistoryTurn) - 1, ty__hengjiang.name)
      end
    end
  end
})

return ty__hengjiang
