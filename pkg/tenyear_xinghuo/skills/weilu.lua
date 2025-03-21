local weilu = fk.CreateSkill {
  name = "weilu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["weilu"] = "威虏",
  [":weilu"] = "锁定技，当你受到其他角色造成的伤害后，伤害来源在你下回合出牌阶段开始时失去体力至1，回合结束时其回复以此法失去的体力值。",

  ["@@weilu"] = "威虏",

  ["$weilu1"] = "贼人势大，需从长计议。",
  ["$weilu2"] = "时机未到，先行撤退。",
}

weilu:addLoseEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    room:removeTableMark(p, "@@weilu", player.id)
  end
end)

weilu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(weilu.name) and
      data.from and not data.from.dead and data.from ~= player
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {data.from}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(data.from, "@@weilu", player.id)
  end,
})
weilu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      table.find(player.room.alive_players, function (p)
        return table.contains(p:getTableMark("@@weilu"), player.id)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local tos = table.filter(player.room:getOtherPlayers(player, false), function (p)
      return table.contains(p:getTableMark("@@weilu"), player.id)
    end)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then return end
      if not p.dead and table.contains(p:getTableMark("@@weilu"), player.id) then
        room:removeTableMark(p, "@@weilu", player.id)
        local n = p.hp - 1
        if n > 0 then
          room:loseHp(p, n, weilu.name)
          if not p.dead and turn_event then
            turn_event:addCleaner(function()
              if not p.dead then
                room:recover{
                  who = p,
                  num = n,
                  recoverBy = p,
                  skillName = weilu.name,
                }
              end
            end)
          end
        end
      end
    end
  end,
})

return weilu
