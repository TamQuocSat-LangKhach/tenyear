local shaxue = fk.CreateSkill {
  name = "shaxue",
}

Fk:loadTranslationTable{
  ["shaxue"] = "铩雪",
  [":shaxue"] = "当你对其他角色造成伤害后，你可以摸两张牌，然后弃置X张牌（X为你计算与该角色的距离）。",

  ["$shaxue1"] = "短兵奋进，杀人于无形。",
  ["$shaxue2"] = "霜刃映雪，三步之内，必取汝性命！",
}

shaxue:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shaxue.name) and data.to ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, shaxue.name)
    if player.dead or data.to.dead or player:isNude() then return end
    local n = player:distanceTo(data.to)
    room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = shaxue.name,
      cancelable = false,
    })
  end,
})

return shaxue
