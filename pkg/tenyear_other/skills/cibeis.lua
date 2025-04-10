local cibeis = fk.CreateSkill {
  name = "cibeis",
}

Fk:loadTranslationTable{
  ["cibeis"] = "慈悲",
  [":cibeis"] = "每回合每名角色限一次，当你对其他角色造成伤害时，你可以防止此伤害，摸五张牌。",

  ["#cibeis-invoke"] = "慈悲：你可以防止对 %dest 造成的伤害，摸五张牌",

  ["$cibeis1"] = "生亦何欢，死亦何苦。",
  ["$cibeis2"] = "我欲成佛，天下无魔；我欲成魔，佛奈我何？",
}

cibeis:addEffect(fk.DamageCaused, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cibeis.name) and player ~= data.to and
      not table.contains(player:getTableMark("cibeis-turn"), data.to.id)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = cibeis.name,
      prompt = "#cibeis-invoke::" .. data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
    player.room:addTableMark(player, "cibeis-turn", data.to.id)
    player:drawCards(5, cibeis.name)
  end,
})

return cibeis
