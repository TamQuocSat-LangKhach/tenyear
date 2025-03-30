local hengjiang = fk.CreateSkill {
  name = "ty__hengjiang",
}

Fk:loadTranslationTable{
  ["ty__hengjiang"] = "横江",
  [":ty__hengjiang"] = "当你受到1点伤害后，你可以令当前回合角色本回合手牌上限-1，此回合结束时，若其本回合弃牌阶段：没有弃置牌，你摸X张牌"..
  "（X为本回合你发动此技能次数）；弃置过牌，你摸一张牌。",

  ["#ty__hengjiang-invoke"] = "横江：是否令 %dest 本回合手牌上限-1？",

  ["$ty__hengjiang1"] = "霸必奋勇杀敌，一雪夷陵之耻！",
  ["$ty__hengjiang2"] = "江横索寒，阻敌绝境之中！",
}

hengjiang:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hengjiang.name) and not player.room.current.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = hengjiang.name,
      prompt = "#ty__hengjiang-invoke::"..room.current.id,
    }) then
      event:setCostData(self, {tos = {room.current}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(target, "@hengjiang-turn", 1)
    room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 1)
  end
})

hengjiang:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:usedEffectTimes(hengjiang.name, Player.HistoryTurn) > 0 and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local phase_ids = {}
    room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
      if e.data.phase == Player.Discard then
        table.insert(phase_ids, {e.id, e.end_id})
      end
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
            if move.from == target and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  return true
                end
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0 then
        player:drawCards(1, hengjiang.name)
      else
        player:drawCards(player:usedEffectTimes(hengjiang.name, Player.HistoryTurn) - 1, hengjiang.name)
      end
    end
  end
})

return hengjiang
