local caixia = fk.CreateSkill {
  name = "caixia"
}

Fk:loadTranslationTable{
  ['caixia'] = '才瑕',
  ['#caixia-draw'] = '你可以发动 才瑕，选择摸牌的数量',
  [':caixia'] = '当你造成或受到伤害后，你可以摸至多X张牌（X为游戏人数且至多为5）。若如此做，此技能失效直到你累计使用了等量的牌。',
  ['$caixia1'] = '吾习扫天下之术，不善净一屋之秽。',
  ['$caixia2'] = '玉有十色五光，微瑕难掩其瑜。',
}

caixia:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(caixia.name) and player:getMark("@caixia") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    for i = 1, math.min(5, #room.players), 1 do
      table.insert(choices, "caixia_draw" .. tostring(i))
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = caixia.name,
      prompt = "#caixia-draw",
    })
    if choice ~= "Cancel" then
      event:setCostData(skill, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, caixia.name, "masochism")
    player:broadcastSkillInvoke(caixia.name)
    local x = tonumber(string.sub(event:getCostData(skill), 12, 12))
    room:setPlayerMark(player, "@caixia", x)
    room:invalidateSkill(player, caixia.name)
    room:drawCards(player, x, caixia.name)
  end,
})

caixia:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(caixia.name, true) and player:getMark("@caixia") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@caixia")
    if player:getMark("@caixia") < 1 then
      room:validateSkill(player, caixia.name)
    end
  end,
})

caixia:on_lose(function (skill, player)
  player.room:setPlayerMark(player, "@caixia", 0)
end)

return caixia
