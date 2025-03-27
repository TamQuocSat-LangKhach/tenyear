local mingjie = fk.CreateSkill {
  name = "mingjie"
}

Fk:loadTranslationTable{
  ['mingjie'] = '命戒',
  [':mingjie'] = '结束阶段，你可以摸一张牌，若此牌为红色，你可以重复此流程直到摸到黑色牌或摸到第三张牌。当你以此法摸到黑色牌时，若你的体力值大于1，你失去1点体力。',
  ['$mingjie1'] = '戒律循规，不可妄贪。',
  ['$mingjie2'] = '王道文明，何无忧平。',
}

mingjie:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mingjie.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card_id = player:drawCards(1, mingjie.name)[1]
    local card = Fk:getCardById(card_id)

    if card.color == Card.Black then
      if player.hp > 1 then
        room:loseHp(player, 1, mingjie.name)
      end
      return
    else
      for i = 1, 2 do
        if room:askToSkillInvoke(player, { skill_name = mingjie.name }) then
          card_id = player:drawCards(1, mingjie.name)[1]
          card = Fk:getCardById(card_id)

          if card.color == Card.Black then
            if player.hp > 1 then
              room:loseHp(player, 1, mingjie.name)
            end
            return
          end
        else
          return
        end
      end
    end
  end,
})

return mingjie
