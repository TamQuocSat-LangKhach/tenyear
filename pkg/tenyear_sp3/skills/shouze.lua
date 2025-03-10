local shouze = fk.CreateSkill {
  name = "shouze"
}

Fk:loadTranslationTable{
  ['shouze'] = '受责',
  ['@dongguiren_jiao'] = '绞',
  [':shouze'] = '锁定技，结束阶段，你弃置一枚“绞”，然后随机获得弃牌堆一张黑色牌并失去1点体力。',
}

shouze:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shouze.name) and player.phase == Player.Finish and player:getMark("@dongguiren_jiao") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@dongguiren_jiao", 1)
    local card = room:getCardsFromPileByRule(".|.|spade,club", 1, "discardPile")
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = shouze.name,
      })
    end
    room:loseHp(player, 1, shouze.name)
  end,
})

return shouze
