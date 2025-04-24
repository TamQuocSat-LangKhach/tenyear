local yingshi = fk.CreateSkill {
  name = "yingshi",
}

Fk:loadTranslationTable{
  ["yingshi"] = "应势",
  [":yingshi"] = "出牌阶段开始时，若没有武将牌旁有“酬”的角色，你可将所有<font color='red'>♥</font>牌置于一名其他角色的武将牌旁，称为“酬”。"..
  "若如此做，当一名角色使用【杀】对武将牌旁有“酬”的角色造成伤害后，其可以获得一张“酬”。当武将牌旁有“酬”的角色死亡时，你获得所有“酬”。",

  ["duji_chou"] = "酬",
  ["#yingshi-choose"] = "应势：你可以将所有<font color='red'>♥</font>牌置为一名角色的“酬”",
  ["#yingshi-invoke"] = "应势：你可以获得 %dest 的一张“酬”",

  ["$yingshi1"] = "应民之声，势民之根。",
  ["$yingshi2"] = "应势而谋，顺民而为。",
}

yingshi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingshi.name) and player.phase == Player.Play and
      not table.find(player.room.alive_players, function(p)
        return #p:getPile("duji_chou") > 0
      end) and
      table.find(player:getCardIds("he"), function(id)
        return Fk:getCardById(id).suit == Card.Heart
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#yingshi-choose",
      skill_name = yingshi.name
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cards = table.filter(player:getCardIds("he"), function(id)
      return Fk:getCardById(id).suit == Card.Heart
    end)
    event:getCostData(self).tos[1]:addToPile("duji_chou", cards, true, yingshi.name)
  end,
})

yingshi:addEffect(fk.Damage, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and data.card.trueName == "slash" and #data.to:getPile("duji_chou") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yingshi.name,
      prompt = "#yingshi-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = { card_data = {{ "duji_chou", data.to:getPile("duji_chou") }} },
      skill_name = yingshi.name,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, yingshi.name, nil, true, player)
  end,
})

return yingshi
