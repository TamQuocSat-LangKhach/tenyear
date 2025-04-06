local skill = fk.CreateSkill {
  name = "#ty__catapult_skill",
  tags = { Skill.Compulsory },
  attached_equip = "ty__catapult",
}

Fk:loadTranslationTable{
  ["#ty__catapult_skill"] = "霹雳车",
}

skill:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card.type == Card.TypeBasic
  end,
  on_use = function(self, event, target, player, data)
    if player.room.current == player then
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
    else
      player:drawCards(1, skill.name)
    end
  end,
})

skill:addEffect(fk.CardResponding, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card.type == Card.TypeBasic and player.room.current ~= player
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, skill.name)
  end,
})

skill:addEffect("targetmod", {
  bypass_distances = function(self, player, _, card)
    return player:hasSkill(skill.name) and Fk:currentRoom().current == player and card and card.type == Card.TypeBasic
  end,
})

return skill
