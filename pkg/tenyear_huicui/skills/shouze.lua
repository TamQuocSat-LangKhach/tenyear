local shouze = fk.CreateSkill {
  name = "shouze",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shouze"] = "受责",
  [":shouze"] = "锁定技，结束阶段，你弃置一枚“绞”，然后随机获得弃牌堆一张黑色牌并失去1点体力。",

  ["$shouze"] = "白绫加之我颈，其罪何患无辞。",
}

shouze:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shouze.name) and player.phase == Player.Finish and
      player:getMark("@dongguiren_jiao") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@dongguiren_jiao", 1)
    local card = room:getCardsFromPileByRule(".|.|spade,club", 1, "discardPile")
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, shouze.name, nil, false, player)
      if player.dead then return end
    end
    room:loseHp(player, 1, shouze.name)
  end,
})

return shouze
