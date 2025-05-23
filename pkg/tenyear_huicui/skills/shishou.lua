local shishou = fk.CreateSkill {
  name = "shishou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shishou"] = "失守",
  [":shishou"] = "锁定技，当你使用【酒】或受到火焰伤害后，你失去1枚“粮”。准备阶段，若你没有“粮”，你失去1点体力。",

  ["$shishou1"] = "腹痛骤发，痛不可当。",
  ["$shishou2"] = "火光冲天，悔不当初。",
}

shishou:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shishou.name) and player.phase == Player.Start and
      player:getMark("@cangchu") == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, shishou.name)
  end,
})

shishou:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shishou.name) and
      player:getMark("@cangchu") > 0 and data.card.name == "analeptic"
  end,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@cangchu")
  end,
})

shishou:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shishou.name) and player:getMark("@cangchu") > 0 and
      data.damageType == fk.FireDamage
  end,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@cangchu")
  end,
})

return shishou
