local tuoxian = fk.CreateSkill {
  name = "tuoxian",
}

Fk:loadTranslationTable{
  ["tuoxian"] = "托献",
  [":tuoxian"] = "每局游戏限一次，当你因〖漂萍〗弃置的牌进入弃牌堆后，你可以将这些牌交给一名其他角色，然后其选择一项：1.弃置其区域内等量的牌；"..
  "2.令〖漂萍〗本回合失效。",

  ["#tuoxian-choose"] = "托献：你可以将这些牌交给一名其他角色，其选择弃置等量牌或令你的〖漂萍〗失效",
  ["tuoxian1"] = "弃置你区域内%arg张牌",
  ["tuoxian2"] = "令%src本回合〖漂萍〗失效",
  ["#tuoxian-discard"] = "托献：弃置你区域内%arg张牌",

  ["$tuoxian1"] = "一贵一贱，其情乃见。",
  ["$tuoxian2"] = "一死一生，乃知交情。",
}

tuoxian:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  times = function(self, player)
    return player:getMark(tuoxian.name) + 1 - player:usedSkillTimes(tuoxian.name, Player.HistoryGame)
  end,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tuoxian.name) and
      player:usedSkillTimes(tuoxian.name, Player.HistoryGame) < player:getMark(tuoxian.name) + 1 then
      local ids = {}
      for _, move in ipairs(data) do
        if move.skillName == "piaoping" and move.moveReason == fk.ReasonDiscard and move.from == player then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
      ids = player.room.logic:moveCardsHoldingAreaCheck(ids)
      return #ids > 0 and #player.room:getOtherPlayers(player, false) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#tuoxian-choose",
      skill_name = tuoxian.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local ids = {}
    for _, move in ipairs(data) do
      if move.skillName == "piaoping" and move.moveReason == fk.ReasonDiscard and move.from == player then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(ids, info.cardId)
        end
      end
    end
    ids = player.room.logic:moveCardsHoldingAreaCheck(ids)
    room:moveCardTo(ids, Card.PlayerHand, to, fk.ReasonGive, tuoxian.name, nil, true, player)
    if to.dead then return end
    local choices = {}
    local n = #ids
    if #table.filter(to:getCardIds("hej"), function (id)
      return not to:prohibitDiscard(id)
    end) >= n then
      table.insert(choices, "tuoxian1:::"..n)
    end
    if player:hasSkill("piaoping", true) then
      table.insert(choices, "tuoxian2:"..player.id)
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = tuoxian.name,
    })
    if choice:startsWith("tuoxian1") then
      local cards = table.filter(to:getCardIds("hej"), function (id)
        return not to:prohibitDiscard(id)
      end)
      cards = room:askToCards(to, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = tuoxian.name,
        pattern = tostring(Exppattern{ id = cards }),
        cancelable = false,
        prompt = "#tuoxian-discard:::"..n,
        expand_pile = to:getCardIds("j"),
      })
      room:throwCard(cards, tuoxian.name, to, to)
    else
      room:invalidateSkill(player, "piaoping", "-turn")
    end
  end,
})

return tuoxian
