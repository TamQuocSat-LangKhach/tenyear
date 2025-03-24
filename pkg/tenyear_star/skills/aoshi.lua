local aoshi = fk.CreateSkill {
  name = "aoshi",
  tags = { Skill.Lord },
  attached_skill_name = "aoshi&",
}

Fk:loadTranslationTable{
  ["aoshi"] = "傲势",
  [":aoshi"] = "主公技，其他群势力角色的出牌阶段限一次，其可以交给你一张手牌，然后你可以发动一次〖纵势〗。",

  ["$aoshi1"] = "无傲骨近于鄙夫，有傲心方为君子。",
  ["$aoshi2"] = "得志则喜，临富贵如何不骄？",
}

aoshi:addAcquireEffect(function (self, player)
  local room = player.room
  for _, p in ipairs(room:getOtherPlayers(player, false)) do
    if p.kingdom == "qun" then
      room:handleAddLoseSkills(p, "aoshi&", nil, false, true)
    else
      room:handleAddLoseSkills(p, "-aoshi&", nil, false, true)
    end
  end
end)

aoshi:addEffect(fk.AfterPropertyChange, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player.kingdom == "qun" and table.find(room.alive_players, function (p)
      return p ~= player and p:hasSkill(aoshi.name, true)
    end) then
      room:handleAddLoseSkills(player, aoshi.attached_skill_name, nil, false, true)
    else
      room:handleAddLoseSkills(player, "-" .. aoshi.attached_skill_name, nil, false, true)
    end
  end,
})

return aoshi
