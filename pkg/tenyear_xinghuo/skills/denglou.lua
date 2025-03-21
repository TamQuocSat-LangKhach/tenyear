local denglou = fk.CreateSkill {
  name = "denglou",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["denglou"] = "登楼",
  [":denglou"] = "限定技，结束阶段，若你没有手牌，你可以亮出牌堆顶四张牌，然后获得其中的非基本牌，并使用其中的基本牌。",

  ["#denglou-use"] = "登楼：你可以使用其中的基本牌",

  ["$denglou1"] = "登兹楼以四望兮，聊暇日以销忧。",
  ["$denglou2"] = "惟日月之逾迈兮，俟河清其未极。",
}

denglou:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(denglou.name) and player.phase == Player.Finish and
      player:isKongcheng() and player:usedSkillTimes(denglou.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4)
    room:turnOverCardsFromDrawPile(player, cards, denglou.name)
    room:delay(1000)
    local get = table.filter(cards, function (id)
      return Fk:getCardById(id).type ~= Card.TypeBasic
    end)
    if #get > 0 then
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonJustMove, denglou.name, nil, true, player)
    end
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    while not player.dead and #cards > 0 do
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = denglou.name,
        prompt = "#denglou-use",
        extra_data = {
          bypass_times = true,
          extra_use = true,
          expand_pile = cards,
        },
        skip = true,
      })
      if use then
        table.removeOne(cards, use.card.id)
        room:useCard(use)
      else
        break
      end
    end
    room:cleanProcessingArea(cards)
  end,
})

return denglou
