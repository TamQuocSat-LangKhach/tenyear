local deshi = fk.CreateSkill {
  name = "deshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["deshi"] = "德释",
  [":deshi"] = "锁定技，当你受到【杀】造成的伤害时，若你已受伤，你防止此伤害并获得一张【杀】，然后减1点体力上限。",

  ["$deshi1"] = "你我素无仇怨，何故欺之太急。",
  ["$deshi2"] = "恃强凌弱，非大丈夫之所为。",
}

deshi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(deshi.name) and
      data.card and data.card.trueName == "slash" and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    local card = room:getCardsFromPileByRule("slash", 1, "allPiles")
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, deshi.name, nil, false, player)
    end
    if not player.dead then
      room:changeMaxHp(player, -1)
    end
  end,
})

return deshi
