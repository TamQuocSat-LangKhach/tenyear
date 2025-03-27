local caixia = fk.CreateSkill {
  name = "caixia",
}

Fk:loadTranslationTable{
  ["caixia"] = "才瑕",
  [":caixia"] = "当你造成或受到伤害后，你可以摸至多X张牌（X为游戏人数且至多为5）。若如此做，此技能失效直到你累计使用了等量的牌。",

  ["#caixia-draw"] = "才瑕：你可以摸至多%arg张牌，此技能失效直到你使用等量张牌",
  ["@caixia"] = "才瑕",

  ["$caixia1"] = "吾习扫天下之术，不善净一屋之秽。",
  ["$caixia2"] = "玉有十色五光，微瑕难掩其瑜。",
}

local spec = {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(caixia.name) and player:getMark("@caixia") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    for i = 1, math.min(5, #room.players), 1 do
      table.insert(choices, tostring(i))
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = caixia.name,
      prompt = "#caixia-draw:::"..math.min(5, #room.players),
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = tonumber(choice)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).choice
    room:setPlayerMark(player, "@caixia", n)
    room:invalidateSkill(player, caixia.name)
    player:drawCards(n, caixia.name)
  end,
}

caixia:addEffect(fk.Damage, spec)
caixia:addEffect(fk.Damaged, spec)

caixia:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(caixia.name, true) and player:getMark("@caixia") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@caixia")
    if player:getMark("@caixia") < 1 then
      room:validateSkill(player, caixia.name)
    end
  end,
})

caixia:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:validateSkill(player, caixia.name)
  room:setPlayerMark(player, "@caixia", 0)
end)

return caixia
