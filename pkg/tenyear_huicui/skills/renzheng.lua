local renzheng = fk.CreateSkill {
  name = "renzheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["renzheng"] = "仁政",
  [":renzheng"] = "锁定技，当有伤害被减少或防止后，你摸两张牌。",

  ["$renzheng1"] = "仁政如水，可润万物。",
  ["$renzheng2"] = "为官一任，当造福一方。",
}

renzheng:addEffect(fk.DamageFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(renzheng.name) then
      if data.prevented or not data.dealtRecorderId then return true end
      if data.extra_data and data.extra_data.renzheng_maxDamage then
        return data.damage < data.extra_data.renzheng_maxDamage
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, renzheng.name)
  end,
})

renzheng:addEffect(fk.AfterSkillEffect, {
  can_refresh = function (self, event, target, player, data)
    return player == player.room.players[1]
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
    if e then
      local dat = e.data
      dat.extra_data = dat.extra_data or {}
      dat.extra_data.renzheng_maxDamage = dat.extra_data.renzheng_maxDamage or 0
      dat.extra_data.renzheng_maxDamage = math.max(dat.damage, dat.extra_data.renzheng_maxDamage)
    end
  end,
})

renzheng:addEffect(fk.SkillEffect, {
  can_refresh = function (self, event, target, player, data)
    return player == player.room.players
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
    if e then
      local dat = e.data
      dat.extra_data = dat.extra_data or {}
      dat.extra_data.renzheng_maxDamage = dat.extra_data.renzheng_maxDamage or 0
      dat.extra_data.renzheng_maxDamage = math.max(dat.damage, dat.extra_data.renzheng_maxDamage)
    end
  end,
})

return renzheng
