local catapultSkill = fk.CreateSkill {
  name = "ty__catapult_skill"
}

Fk:loadTranslationTable{
  ['#ty__catapult_skill'] = '霹雳车',
  ['ty__catapult'] = '霹雳车',
}

catapultSkill:addEffect(fk.CardUsing, {
  attached_equip = "ty__catapult",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(catapultSkill) and data.card.type == Card.TypeBasic
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.CardUsing and player.phase ~= Player.NotActive then
      if data.card.is_damage_card then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      elseif data.card.name == "peach" then
        data.additionalRecover = (data.additionalRecover or 0) + 1
      elseif data.card.name == "analeptic" then
        if data.extra_data and data.extra_data.analepticRecover then
          data.additionalRecover = (data.additionalRecover or 0) + 1
        else
          data.extra_data = data.extra_data or {}
          data.extra_data.additionalDrank = (data.extra_data.additionalDrank or 0) + 1
        end
      end
    elseif player.phase == Player.NotActive then
      player:drawCards(1, catapultSkill.name)
    end
  end,
})

catapultSkill:addEffect(fk.CardResponding, {
  attached_equip = "ty__catapult",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(catapultSkill) and data.card.type == Card.TypeBasic
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.CardUsing and player.phase ~= Player.NotActive then
      if data.card.is_damage_card then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      elseif data.card.name == "peach" then
        data.additionalRecover = (data.additionalRecover or 0) + 1
      elseif data.card.name == "analeptic" then
        if data.extra_data and data.extra_data.analepticRecover then
          data.additionalRecover = (data.additionalRecover or 0) + 1
        else
          data.extra_data = data.extra_data or {}
          data.extra_data.additionalDrank = (data.extra_data.additionalDrank or 0) + 1
        end
      end
    elseif player.phase == Player.NotActive then
      player:drawCards(1, catapultSkill.name)
    end
  end,
})

catapultSkill:addEffect('targetmod', {
  bypass_distances = function(self, player, skillParam, card)
    return player:hasSkill(catapultSkill) and player.phase ~= Player.NotActive and card and card.type == Card.TypeBasic
  end,
})

return catapultSkill
