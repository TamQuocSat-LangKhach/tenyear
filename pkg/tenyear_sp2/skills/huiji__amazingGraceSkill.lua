local huiji__amazingGraceSkill = fk.CreateSkill {
  name = "huiji__amazing_grace_skill"
}

Fk:loadTranslationTable{ }

huiji__amazingGraceSkill:addEffect('active', {
  prompt = "#amazing_grace_skill",
  can_use = Util.GlobalCanUse,
  on_use = Util.GlobalOnUse,
  mod_target_filter = Util.TrueFunc,
  on_action = function(self, room, use, finished)
    local player = room:getPlayerById(use.from)
    if not finished then
      local toDisplay = player:getCardIds(Player.Hand)
      room:moveCardTo(toDisplay, Card.Processing, nil, fk.ReasonJustMove, huiji__amazingGraceSkill.name, "", true, player.id)

      table.forEach(room.players, function(p)
        room:fillAG(p, toDisplay)
      end)

      use.extra_data = use.extra_data or {}
      use.extra_data.AGFilled = toDisplay
    else
      if use.extra_data and use.extra_data.AGFilled then
        table.forEach(room.players, function(p)
          room:closeAG(p)
        end)

        local toDiscard = table.filter(use.extra_data.AGFilled, function(id)
          return room:getCardArea(id) == Card.Processing
        end)

        if #toDiscard > 0 then
          if player.dead then
            room:moveCards({
              ids = toDiscard,
              toArea = Card.DiscardPile,
              moveReason = fk.ReasonPutIntoDiscardPile,
            })
          else
            room:moveCardTo(toDiscard, Card.PlayerHand, player, fk.ReasonJustMove, huiji__amazingGraceSkill.name, "", true, player.id)
          end
        end
      end

      use.extra_data.AGFilled = nil
    end
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    if not (effect.extra_data and effect.extra_data.AGFilled and #effect.extra_data.AGFilled > 0) then
      return
    end

    local chosen = room:askToAG(to, {
      id_list = effect.extra_data.AGFilled,
      cancelable = false,
      skill_name = "amazing_grace_skill"
    })
    room:takeAG(to, chosen, room.players)
    room:obtainCard(effect.to, chosen, true, fk.ReasonPrey)
    table.removeOne(effect.extra_data.AGFilled, chosen)
  end,
})

return huiji__amazingGraceSkill
