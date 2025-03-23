local lingyue = fk.CreateSkill {
  name = "lingyue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lingyue"] = "聆乐",
  [":lingyue"] = "锁定技，一名角色每轮首次造成伤害后，你摸一张牌。若此时是该角色回合外，改为摸X张牌（X为本回合全场造成的伤害值）。",

  ["$lingyue1"] = "宫商催角羽，仙乐自可聆。",
  ["$lingyue2"] = "玉琶奏折柳，天地尽箫声。",
}

lingyue:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(lingyue.name) and target and not table.contains(player:getTableMark("lingyue-round"), target.id) then
      local damage_events = player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == target
      end, Player.HistoryRound)
      if #damage_events == 1 then
        player.room:addTableMark(player, "lingyue-round", target.id)
        if damage_events[1].data == data then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room.current ~= target then
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return end
      local n = 0
      room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data
        if damage.from then
          n = n + damage.damage
        end
      end, Player.HistoryTurn)
      if n > 0 then
        player:drawCards(n, lingyue.name)
      end
    else
      player:drawCards(1, lingyue.name)
    end
  end,
})

return lingyue
