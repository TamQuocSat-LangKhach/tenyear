local aoshi = fk.CreateSkill {
  name = "aoshi$"
}

Fk:loadTranslationTable{
  ['aoshi_other&'] = '傲势',
}

aoshi:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player)
    return target == player
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    if player.kingdom == "qun" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(aoshi.name, true)
    end) then
      room:handleAddLoseSkills(player, "aoshi_other&", nil, false, true)
    else
      room:handleAddLoseSkills(player, "-aoshi_other&", nil, false, true)
    end
  end,
})

aoshi:addEffect("on_acquire", {
  on_acquire = function(self, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p ~= player and p.kingdom == "qun" then
        room:handleAddLoseSkills(p, aoshi.attached_skill_name, nil, false, true)
      end
    end
  end,
})

return aoshi
