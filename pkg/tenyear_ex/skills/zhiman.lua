local zhiman = fk.CreateSkill {
  name = "ty_ex__zhiman",
}

Fk:loadTranslationTable{
  ["ty_ex__zhiman"] = "制蛮",
  [":ty_ex__zhiman"] = "当你对其他角色造成伤害时，你可以防止此伤害，然后获得其区域内一张牌。",

  ["#ty_ex__zhiman-invoke"] = "制蛮：你可以防止对 %dest 造成的伤害，获得其区域内一张牌",

  ["$ty_ex__zhiman1"] = "断其粮草，不战而胜！",
  ["$ty_ex__zhiman2"] = "用兵之道，攻心为上！",
}

zhiman:addEffect(fk.DamageCaused, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhiman.name) and data.to ~= player
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zhiman.name,
      prompt = "#ty_ex__zhiman-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    if not data.to:isAllNude() then
      local card = room:askToChooseCard(player, {
        target = data.to,
        flag = "hej",
        skill_name = zhiman.name,
      })
      room:obtainCard(player, card, true, fk.ReasonPrey, player, zhiman.name)
    end
  end,
})

return zhiman
