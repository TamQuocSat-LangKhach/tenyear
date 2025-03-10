local zhongyanz = fk.CreateSkill {
  name = "zhongyanz"
}

Fk:loadTranslationTable{
  ['zhongyanz'] = '忠言',
  ['#zhongyanz'] = '忠言：亮出牌堆顶三张牌，令一名角色用一张手牌交换其中一张牌',
  ['#zhongyanz-exchange'] = '忠言：请用一张手牌交换其中一张牌',
  ['zhongyanz_prey'] = '获得场上一张牌',
  [':zhongyanz'] = '出牌阶段限一次，你可展示牌堆顶三张牌，令一名角色将一张手牌交换其中一张牌。然后若这些牌颜色相同，其选择回复1点体力或获得场上一张牌；若该角色不为你，你执行另一项。',
  ['$zhongyanz1'] = '腹有珠玑，可坠在殿之玉盘。',
  ['$zhongyanz2'] = '胸纳百川，当汇凌日之沧海。',
}

zhongyanz:addEffect('active', {
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(zhongyanz.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 1,
  prompt = "#zhongyanz",
  card_filter = Util.FalseFunc,
  target_filter = function (skill, player, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = zhongyanz.name,
      proposer = player.id,
    })
    if to.dead or to:isKongcheng() then
      room:moveCards({
        ids = cards,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = zhongyanz.name,
      })
      return
    end
    local results = room:askToExchange(to, {
      piles_name = {"Top"},
      pattern = "hand_card",
      cards = cards,
      from_area = to:getCardIds("h"),
      prompt = "#zhongyanz-exchange",
      max_num = 1,
      cancelable = false
    })
    local to_hand = {}
    if #results > 0 then
      to_hand = table.filter(results, function(id)
        return table.contains(cards, id)
      end)
      table.removeOne(results, to_hand[1])
      for i = #cards, 1, -1 do
        if cards[i] == to_hand[1] then
          cards[i] = results[1]
          break
        end
      end
    else
      to_hand, cards[1] = {cards[1]}, to:getCardIds("h")[1]
    end
    U.swapCardsWithPile(to, cards, to_hand, zhongyanz.name, "Top", false, player.id)
    if to.dead then return end
    if table.every(cards, function(id)
      return Fk:getCardById(id).color == Fk:getCardById(cards[1]).color
    end) then
      local choices = {"recover", "zhongyanz_prey"}
      local choice = room:askToChoice(to, {
        choices = choices,
        skill_name = zhongyanz.name
      })
      DoZhongyanz(to, player, choice)
      if to ~= player then
        table.removeOne(choices, choice)
        DoZhongyanz(player, player, choices[1])
      end
    end
  end,
})

return zhongyanz
