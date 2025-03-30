local minshan = fk.CreateSkill {
  name = "minshan",
}

Fk:loadTranslationTable{
  ["minshan"] = "愍善",
  [":minshan"] = "当你受到伤害后，你可以令一名角色随机获得牌堆里的两张与伤害牌花色相同的牌。",

  ["#minshan-choose"] = "愍善：你可以令一名角色随机获得两张%arg牌",

  ["$minshan1"] = "红颜易老，恻隐之心未褪。",
  ["$minshan2"] = "心虽存微妒，见落叶而怆然。",
}

minshan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(minshan.name) and
      data.card and data.card.suit ~= Card.NoSuit
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = minshan.name,
      prompt = "#minshan-choose:::"..data.card:getSuitString(true),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|"..data.card:getSuitString(), 2, "drawPile")
    if #cards > 0 then
      room:obtainCard(event:getCostData(self).tos[1], cards, false, fk.ReasonJustMove, player, minshan.name)
    end
  end,
})

return minshan
