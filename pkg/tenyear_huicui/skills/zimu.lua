local zimu = fk.CreateSkill {
  name = "zimu"
}

Fk:loadTranslationTable{
  ['zimu'] = '自牧',
  ['@@pijing'] = '辟境',
  [':zimu'] = '锁定技，当你受到伤害后，有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗。',
  ['$zimu'] = '既为汉吏，当遵汉律。',
}

zimu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill(zimu.name, true) then
        p:drawCards(1, zimu.name)
      end
    end
    room:handleAddLoseSkills(player, "-" .. zimu.name, nil, true, false)
  end,
})

zimu:addEffect(fk.EventAcquireSkill, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data == skill
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@pijing", 1)
  end,
})

zimu:addEffect(fk.EventLoseSkill, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data == skill
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@pijing", 0)
  end,
})

return zimu
