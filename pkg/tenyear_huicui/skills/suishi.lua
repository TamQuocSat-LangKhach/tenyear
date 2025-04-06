local suishi = fk.CreateSkill {
  name = "ty__suishi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__suishi"] = "随势",
  [":ty__suishi"] = "锁定技，当其他角色进入濒死状态时，若伤害来源与你势力相同，你摸一张牌；当其他角色死亡时，若其与你势力相同，"..
  "你弃置至少一张手牌。",

  ["$ty__suishi1"] = "一荣俱荣！",
  ["$ty__suishi2"] = "一损俱损……",
}

suishi:addEffect(fk.EnterDying, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(suishi.name) and target ~= player and
      data.damage and data.damage.from and player.kingdom == data.damage.from.kingdom
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, suishi.name, "drawcard")
    player:broadcastSkillInvoke(suishi.name, 1)
    player:drawCards(1, suishi.name)
  end,
})

suishi:addEffect(fk.Death, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(suishi.name) and target ~= player and player.kingdom == target.kingdom
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, suishi.name, "negative")
    player:broadcastSkillInvoke(suishi.name, 2)
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = suishi.name,
      cancelable = false,
    })
  end,
})

return suishi
