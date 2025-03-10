local yingshi = fk.CreateSkill {
  name = "yingshi"
}

Fk:loadTranslationTable{
  ['yingshi'] = '应势',
  ['duji_chou'] = '酬',
  ['#yingshi-choose'] = '应势：你可以将所有<font color=>♥</font>牌置为一名角色的“酬”',
  ['#yingshi-get'] = '应势：你可以获得一张“酬”',
  [':yingshi'] = '出牌阶段开始时，若没有武将牌旁有“酬”的角色，你可将所有<font color=>♥</font>牌置于一名其他角色的武将牌旁，称为“酬”。若如此做，当一名角色使用【杀】对武将牌旁有“酬”的角色造成伤害后，其可以获得一张“酬”。当武将牌旁有“酬”的角色死亡时，你获得所有“酬”。',
  ['$yingshi1'] = '应民之声，势民之根。',
  ['$yingshi2'] = '应势而谋，顺民而为。',
}

yingshi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player.phase == Player.Play and
      not table.find(player.room.alive_players, function(p) return #p:getPile("duji_chou") > 0 end) and
      table.find(player:getCardIds("he"), function(id) return Fk:getCardById(id).suit == Card.Heart end)
  end,
  on_cost = function(self, event, target, player)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#yingshi-choose",
      skill_name = skill.name
    })
    if #to > 0 then
      event:setCostData(skill, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = table.filter(player:getCardIds("he"), function(id) return Fk:getCardById(id).suit == Card.Heart end)
    room:getPlayerById(event:getCostData(skill)):addToPile("duji_chou", cards, true, skill.name)
  end,
})

yingshi:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player)
    return #target:getPile("duji_chou") > 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:moveCardTo(target:getPile("duji_chou"), Card.PlayerHand, player, fk.ReasonJustMove, skill.name, nil, true, player.id)
  end,
})

yingshi:addEffect(fk.Damage, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and data.card.trueName == "slash" and #data.to:getPile("duji_chou") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards, choice = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = {data.to},
      min_target_num = 0,
      max_target_num = 0,
      prompt = "#yingshi-get",
      skill_name = "yingshi"
    })
    if #cards > 0 then
      room:moveCardTo(Fk:getCardById(cards[1]), Card.PlayerHand, player, fk.ReasonJustMove, "yingshi", nil, true, player.id)
    end
  end,
})

return yingshi
