local ty__suishi = fk.CreateSkill {
  name = "ty__suishi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['ty__suishi'] = '随势',
  [':ty__suishi'] = '锁定技，当其他角色进入濒死状态时，若伤害来源与你势力相同，你摸一张牌；当其他角色死亡时，若其与你势力相同，你弃置至少一张手牌。',
  ['$ty__suishi1'] = '一荣俱荣！',
  ['$ty__suishi2'] = '一损俱损……',
}

ty__suishi:addEffect(fk.EnterDying, {
  
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(ty__suishi) or target == player then return false end
    if event == fk.EnterDying then
      return data.damage and data.damage.from and player.kingdom == data.damage.from.kingdom
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      room:notifySkillInvoked(player, ty__suishi.name, "drawcard")
      player:broadcastSkillInvoke(ty__suishi.name, 1)
      player:drawCards(1, ty__suishi.name)
    end
  end,
})

ty__suishi:addEffect(fk.Death, {
  
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(ty__suishi) or target == player then return false end
    return player.kingdom == target.kingdom and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ty__suishi.name, "negative")
    player:broadcastSkillInvoke(ty__suishi.name, 2)
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = ty__suishi.name,
      cancelable = false,
    })
  end,
})

return ty__suishi
