local aoren = fk.CreateSkill {
  name = "aoren"
}

Fk:loadTranslationTable{
  ['aoren'] = '鏖刃',
  ['#aoren-prey'] = '鏖刃：是否收回此%arg？',
  [':aoren'] = '每轮限X次（为〖暮锐〗已删除选项数），你使用基本牌结算完毕后，可以将之收回手牌。',
  ['$aoren1'] = '为国效死，百战不殆。',
  ['$aoren2'] = '血染沙场，一往无前。',
}

aoren:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aoren.name) and data.card.type == Card.TypeBasic and
      player:usedSkillTimes(aoren.name, Player.HistoryRound) < player:getMark(aoren.name) and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = aoren.name,
      prompt = "#aoren-prey:::"..data.card:toLogString()
    })
  end,
  on_use = function (self, event, target, player, data)
    player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, aoren.name, nil, true, player.id)
  end,
})

return aoren
