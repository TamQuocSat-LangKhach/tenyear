local zhuide = fk.CreateSkill {
  name = "zhuide",
}

Fk:loadTranslationTable{
  ["zhuide"] = "追德",
  [":zhuide"] = "当你死亡时，你可以令一名其他角色摸四张不同牌名的基本牌。",

  ["#zhuide-choose"] = "追德：你可以令一名角色摸四张不同牌名的基本牌",

  ["$zhuide1"] = "思美人，两情悦。",
  ["$zhuide2"] = "花香蝶恋，君德妾慕。",
}

zhuide:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuide.name, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#zhuide-choose",
      skill_name = zhuide.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cardMap = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        local list = cardMap[card.trueName] or {}
        table.insert(list, id)
        cardMap[tostring(card.trueName)] = list
      end
    end
    local cards, names = {}, {}
    for name, _ in pairs(cardMap) do
      table.insert(names, name)
    end
    names = table.random(names, 4)
    for _, name in ipairs(names) do
      table.insert(cards, table.random(cardMap[name]))
    end
    if #cards > 0 then
      room:obtainCard(to, cards, true, fk.ReasonDraw, to, zhuide.name)
    end
  end,
})

return zhuide
