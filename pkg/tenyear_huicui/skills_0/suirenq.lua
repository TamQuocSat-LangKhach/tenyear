local suirenq = fk.CreateSkill {
  name = "suirenq"
}

Fk:loadTranslationTable{
  ['suirenq'] = '随认',
  ['#suirenq-choose'] = '随认：你可以将手牌中所有【杀】和伤害锦囊牌交给一名角色',
  [':suirenq'] = '你死亡时，可以将手牌中所有【杀】和伤害锦囊牌交给一名其他角色。',
  ['$suirenq1'] = '就交给你了。',
  ['$suirenq2'] = '我的财富，收好！'
}

suirenq:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(suirenq.name, false, true) and
      table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id).is_damage_card end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, Util.IdMapper)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#suirenq-choose",
      skill_name = suirenq.name
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local cards = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).is_damage_card end)
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, suirenq.name, nil, false, player.id)
  end,
})

return suirenq
