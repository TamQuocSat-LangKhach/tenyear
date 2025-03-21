local sibian = fk.CreateSkill {
  name = "sibian"
}

Fk:loadTranslationTable{
  ['sibian'] = '思辩',
  ['#sibian-choose'] = '思辩：你可以将剩余的牌交给一名手牌数最少的角色',
  [':sibian'] = '摸牌阶段，你可以放弃摸牌，改为亮出牌堆顶的4张牌，你获得其中所有点数最大和最小的牌，然后你可以将剩余的牌交给一名手牌数最少的角色。',
  ['$sibian1'] = '才藻俊茂，辨思如涌。',
  ['$sibian2'] = '弘雅之素，英秀之德。',
}

sibian:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sibian.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = sibian.name,
      proposer = player.id,
    })
    local min, max = 13, 1
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).number < min then
        min = Fk:getCardById(id).number
      end
      if Fk:getCardById(id).number > max then
        max = Fk:getCardById(id).number
      end
    end
    local get = {}
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).number == min or Fk:getCardById(cards[i]).number == max then
        table.insert(get, cards[i])
        table.removeOne(cards, cards[i])
      end
    end
    room:delay(1000)
    room:obtainCard(player, get, false, fk.ReasonJustMove)
    if #cards > 0 then
      local n = #player.player_cards[Player.Hand]
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if #p.player_cards[Player.Hand] < n then
          n = #p.player_cards[Player.Hand]
        end
      end
      local targets = {}
      for _, p in ipairs(room:getAlivePlayers()) do
        if #p.player_cards[Player.Hand] == n then
          table.insert(targets, p)
        end
      end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#sibian-choose",
        skill_name = sibian.name,
        cancelable = true,
      })
      if #to > 0 then
        room:obtainCard(to[1], cards, false, fk.ReasonGive, player.id)
      else
        room:moveCards({
          ids = cards,
          fromArea = Card.Processing,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonJustMove,
          skillName = sibian.name,
        })
      end
    end
    return true
  end,
})

return sibian
