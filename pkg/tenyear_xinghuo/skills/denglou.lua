local denglou = fk.CreateSkill {
  name = "denglou"
}

Fk:loadTranslationTable{
  ['denglou'] = '登楼',
  [':denglou'] = '限定技，结束阶段开始时，若你没有手牌，你可以亮出牌堆顶四张牌，然后获得其中的非基本牌，并使用其中的基本牌（不使用则置入弃牌堆）。',
  ['$denglou1'] = '登兹楼以四望兮，聊暇日以销忧。',
  ['$denglou2'] = '惟日月之逾迈兮，俟河清其未极。',
}

denglou:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Limited,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name) and target == player and player.phase == Player.Finish and player:isKongcheng() and player:usedSkillTimes(denglou.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = U.turnOverCardsFromDrawPile(player, 4, denglou.name)
    room:delay(500)
    local get = {}
    for i = 4, 1, -1 do
      if Fk:getCardById(cards[i]).type ~= Card.TypeBasic then
        table.insert(get, table.remove(cards, i))
      end
    end
    if #get > 0 then
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonPrey, denglou.name)
    end
    while not player.dead and #cards > 0 do
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = denglou.name,
        bypass_times = true,
        extra_use = true,
        expand_pile = cards,
      })
      if use then
        table.removeOne(cards, use.card.id)
      else
        break
      end
    end
    room:cleanProcessingArea(cards, denglou.name)
  end,
})

return denglou
