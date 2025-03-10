local saowei = fk.CreateSkill {
  name = "saowei"
}

Fk:loadTranslationTable{
  ['saowei'] = '扫围',
  ['@@aishou-inhand'] = '隘',
  ['#saowei-use'] = '扫围：你可以将一张“隘”当【杀】对目标角色使用',
  [':saowei'] = '当其他角色使用【杀】结算后，若目标角色不为你且目标角色在你的攻击范围内，你可以将一张“隘”当【杀】对该目标角色使用。若此【杀】造成伤害，你获得之。',
  ['$saowei1'] = '今从王师猎虎，必擒吕布。',
  ['$saowei2'] = '七军围猎，虓虎插翅难逃。',
}

saowei:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(saowei.name) and target ~= player and data.card.trueName == "slash" and
      table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 end) and
      table.find(TargetGroup:getRealTargets(data.tos), function(id)
        local p = player.room:getPlayerById(id)
        return id ~= player.id and not p.dead and player:inMyAttackRange(p) and not player:isProhibited(p, Fk:cloneCard("slash"))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(TargetGroup:getRealTargets(data.tos), function(id)
      local p = room:getPlayerById(id)
      return id ~= player.id and not p.dead and player:inMyAttackRange(p) and not player:isProhibited(p, Fk:cloneCard("slash"))
    end)
    local ids = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@aishou-inhand") > 0 end)
    local tos, id = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = targets,
      min_target_num = 1,
      max_target_num = 1,
      pattern = ".|.|.|.|.|." .. table.concat(ids, ","),
      prompt = "#saowei-use",
    })
    if #tos > 0 then
      event:setCostData(self, {tos, id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("slash")
    card:addSubcard(event:getCostData(self)[2])
    card.skillName = saowei.name
    local use = {
      from = player.id,
      tos = {event:getCostData(self)[1]},
      card = card,
      extraUse = true,
    }
    use.card.skillName = saowei.name
    room:useCard(use)
    if use.damageDealt and not player.dead and room:getCardArea(use.card) == Card.DiscardPile then
      room:obtainCard(player.id, use.card, true, fk.ReasonJustMove)
    end
  end,
})

return saowei
