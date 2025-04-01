local jichou = fk.CreateSkill {
  name = "jichouw",
}

Fk:loadTranslationTable{
  ["jichouw"] = "集筹",
  [":jichouw"] = "结束阶段，若你本回合使用的牌名均不同，你可以从弃牌堆中将这些牌交给你选择的角色各一张，然后摸X张牌"..
  "（X为其中此前没有因此给出过的牌名张数）。",

  ["#jichouw-give"] = "集筹：你可以将这些牌分配给每名角色各一张",
  ["@$jichouw"] = "集筹",

  ["$jichouw1"] = "备武枕戈，待天下风起之时。",
  ["$jichouw2"] = "定淮联兖，邀群士共襄大义。",
}

jichou:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jichou.name) and player.phase == Player.Finish then
      local room = player.room
      local names = {}
      local cards = {}

      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == player then
          if table.contains(names, use.card.trueName) then
            cards = {}
            return true
          end
          table.insert(names, use.card.trueName)
          table.insertTableIfNeed(cards, Card:getIdList(use.card))
        end
      end, Player.HistoryTurn)

      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)

      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(self).cards)
    local results = room:askToYiji(player, {
      min_num = 0,
      max_num = #cards,
      skill_name = jichou.name,
      targets = room.alive_players,
      cards = cards,
      prompt = "#jichouw-give",
      expand_pile = cards,
      single_max = 1,
      skip = true,
    })
    for _, ids in pairs(results) do
      if #ids > 0 then
        event:setCostData(self, {extra_data = results})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local results = event:getCostData(self).extra_data
    local names = {}
    for _, ids in pairs(results) do
      for _, id in ipairs(ids) do
        table.insertIfNeed(names, Fk:getCardById(id).trueName)
      end
    end
    local x = 0
    local mark = player:getTableMark("@$jichouw")
    for _, name in ipairs(names) do
      if table.insertIfNeed(mark, name) then
        x = x + 1
      end
    end
    if x > 0 then
      room:setPlayerMark(player, "@$jichouw", mark)
    end
    room:doYiji(results, player, jichou.name)
    if player.dead then return end
    if x > 0 and not player.dead then
      player:drawCards(x, jichou.name)
    end
  end,
})

jichou:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@$jichouw", 0)
end)

return jichou
