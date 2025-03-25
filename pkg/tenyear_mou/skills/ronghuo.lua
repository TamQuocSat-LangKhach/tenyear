local ronghuo = fk.CreateSkill {
  name = "ronghuo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ronghuo"] = "融火",
  [":ronghuo"] = "锁定技，你使用火【杀】或【火攻】造成的伤害值改为X（X为全场势力数）。",

  ["$ronghuo1"] = "火莲绽江矶，炎映三千弱水。",
  ["$ronghuo2"] = "奇志吞樯橹，潮平百万寇贼。",
}

ronghuo:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ronghuo.name) and data.card and
      table.contains({"fire_attack", "fire__slash"}, data.card.name) and
      player.room.logic:damageByCardEffect()
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    data:changeDamage(#kingdoms - data.damage)
  end,
})

return ronghuo
