local lingyue = fk.CreateSkill {
  name = "lingyue"
}

Fk:loadTranslationTable{
  ['lingyue'] = '聆乐',
  [':lingyue'] = '锁定技，一名角色在本轮首次造成伤害后，你摸一张牌。若此时是该角色回合外，改为摸X张牌（X为本回合全场造成的伤害值）。',
  ['$lingyue1'] = '宫商催角羽，仙乐自可聆。',
  ['$lingyue2'] = '玉琶奏折柳，天地尽箫声。',
}

lingyue:addEffect(fk.Damage, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(lingyue.name) or not target then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local x = target:getMark("lingyue_record-round")
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event and first_damage_event.data[1].from == target then
            x = first_damage_event.id
            room:setPlayerMark(target, "lingyyue_record-round", x)
            return true
          end
        end
      end, Player.HistoryRound)
    end
    return damage_event.id == x
  end,
  on_use = function(self, event, target, player, data)
    if target.phase == Player.NotActive then
      local room = player.room
      local events = room.logic.event_recorder[GameEvent.ChangeHp] or Util.DummyTable
      local end_id = player:getMark("lingyue_record-turn")
      if end_id == 0 then
        local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
        if not turn_event then
          player:drawCards(1, lingyue.name)
          return false
        end
        end_id = turn_event.id
      end
      room:setPlayerMark(player, "lingyue_record-turn", room.logic.current_event_id)
      local x = player:getMark("lingyue_damage-turn")
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id <= end_id then break end
        local damage = e.data[5]
        if damage and damage.from then
          x = x + damage.damage
        end
      end
      room:setPlayerMark(player, "lingyue_damage-turn", x)
      if x > 0 then
        player:drawCards(x, lingyue.name)
      end
    else
      player:drawCards(1, lingyue.name)
    end
  end,
})

return lingyue
