local caisi = fk.CreateSkill {
  name = "caisi"
}

Fk:loadTranslationTable{
  ['caisi'] = '才思',
  [':caisi'] = '当你于回合内/回合外使用基本牌后，你可以从牌堆/弃牌堆随机获得一张非基本牌。每次发动该技能后，若发动次数：小于等于体力上限：本回合下次获得牌张数翻倍；大于体力上限：本回合此技能失效。',
  ['$caisi1'] = '扶耒耜，植桑陌，习诗书，以传家。',
  ['$caisi2'] = '惟楚有才，于庞门为盛。',
}

caisi:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(caisi.name) and data.card.type == Card.TypeBasic
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = 2 ^ (player:usedSkillTimes(caisi.name) - 1)
    local cards = {}
    if player.phase == Player.NotActive then
      cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", x, "discardPile")
    else
      cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", x)
    end
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, caisi.name, nil, false, player.id)
    end
    if player:usedSkillTimes(caisi.name) > player.maxHp then
      room:invalidateSkill(player, caisi.name, "-turn")
    end
  end,
})

return caisi
