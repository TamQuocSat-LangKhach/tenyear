local shishou = fk.CreateSkill {
  name = "shishou"
}

Fk:loadTranslationTable{
  ['shishou'] = '失守',
  ['@cangchu'] = '粮',
  [':shishou'] = '锁定技，当你使用【酒】或受到火焰伤害后，你失去1枚“粮”。准备阶段，若你没有“粮”，你失去1点体力。',
  ['$shishou1'] = '腹痛骤发，痛不可当。',
  ['$shishou2'] = '火光冲天，悔不当初。',
}

shishou:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Compulsory,
  anim_type = "negative",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name) and target == player and player.phase == Player.Start and player:getMark("@cangchu") == 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:loseHp(player, 1, shishou.name)
  end,
})

shishou:addEffect(fk.CardUseFinished, {
  frequency = Skill.Compulsory,
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and target == player and player:getMark("@cangchu") > 0 and data.card.name == "analeptic"
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:removePlayerMark(player, "@cangchu")
    room:broadcastProperty(player, "MaxCards")
  end,
})

shishou:addEffect(fk.Damaged, {
  frequency = Skill.Compulsory,
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and target == player and player:getMark("@cangchu") > 0 and data.damageType == fk.FireDamage
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:removePlayerMark(player, "@cangchu")
    room:broadcastProperty(player, "MaxCards")
  end,
})

return shishou
