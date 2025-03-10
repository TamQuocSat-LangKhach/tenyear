local tuoxian = fk.CreateSkill {
  name = "tuoxian"
}

Fk:loadTranslationTable{
  ['tuoxian'] = '托献',
  ['piaoping'] = '漂萍',
  ['#tuoxian-choose'] = '托献：你可以将这些牌交给一名其他角色，其选择弃置等量牌或令你的〖漂萍〗失效',
  ['tuoxian1'] = '弃置你区域内%arg张牌',
  ['tuoxian2'] = '令 %src 本回合〖漂萍〗失效',
  ['#tuoxian-choice'] = '托献：%src 令你选择一项',
  ['#tuoxian-discard'] = '托献：弃置你区域内%arg张牌',
  [':tuoxian'] = '每局游戏限一次，当你因〖漂萍〗弃置的牌进入弃牌堆后，你可以改为将这些牌交给一名其他角色，然后其选择一项：1.其弃置其区域内等量的牌；2.令〖漂萍〗本回合失效。',
  ['$tuoxian1'] = '一贵一贱，其情乃见。',
  ['$tuoxian2'] = '一死一生，乃知交情。',
}

tuoxian:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tuoxian.name) and player:usedSkillTimes(tuoxian.name, Player.HistoryGame) < player:getMark(tuoxian.name) + 1 then
      for _, move in ipairs(data) do
        if move.skillName == "piaoping" and move.moveReason == fk.ReasonDiscard and move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if player.room:getCardArea(info.cardId) == Card.DiscardPile then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#tuoxian-choose",
      skill_name = tuoxian.name
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local to_get = {}
    for _, move in ipairs(data) do
      if move.skillName == "piaoping" and move.moveReason == fk.ReasonDiscard and move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if room:getCardArea(info.cardId) == Card.DiscardPile then
            table.insert(to_get, info.cardId)
          end
        end
      end
    end
    room:moveCardTo(to_get, Card.PlayerHand, to, fk.ReasonGive, tuoxian.name, nil, false, player.id)
    local choices = {}
    local n = #to_get
    if not to.dead and #to:getCardIds("hej") >= n then
      table.insert(choices, "tuoxian1:::"..n)
    end
    if not player.dead then
      table.insert(choices, "tuoxian2:"..player.id)
    end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = tuoxian.name,
      prompt = "#tuoxian-choice:"..player.id
    })
    if choice[8] == "1" then
      local cards = room:askToChooseCards(to, {
        min_num = n,
        max_num = n,
        target = to,
        flag = "hej",
        skill_name = tuoxian.name,
        prompt = "#tuoxian-discard:::"..n
      })
      room:throwCard(cards, tuoxian.name, to)
    else
      room:setPlayerMark(player, "piaoping_invalid-turn", 1)
    end
    return true
  end,
})

return tuoxian
