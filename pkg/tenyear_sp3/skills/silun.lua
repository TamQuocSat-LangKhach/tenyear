local silun = fk.CreateSkill {
  name = "silun"
}

Fk:loadTranslationTable{
  ['silun'] = '四论',
  ['silun_active'] = '四论',
  ['#silun-card'] = '四论：将一张牌置于场上、牌堆顶或牌堆底（第%arg张/共4张）',
  ['Field'] = '场上',
  [':silun'] = '准备阶段或当你受到伤害后，你可以摸四张牌，然后将四张牌依次置于场上、牌堆顶或牌堆底，若此牌为你装备区里的牌，你复原武将牌，若你将装备牌置于一名角色装备区，其复原武将牌。',
  ['$silun1'] = '习守静之术，行务时之风。',
  ['$silun2'] = '纵笔瑞白雀，满座尽高朋。',
}

silun:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(silun.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:drawCards(4, silun.name)
    for i = 1, 4, 1 do
      if player.dead or player:isNude() then return end
      local _, dat = room:askToUseActiveSkill(player, {
        skill_name = "silun_active",
        prompt = "#silun-card:::" .. tostring(i),
        cancelable = false,
      })
      local card_id = dat and dat.cards[1] or player:getCardIds("he")[1]
      local choice = dat and dat.interaction or "Top"
      local reset_self = room:getCardArea(card_id) == Card.PlayerEquip
      if choice == "Field" then
        local to = room:getPlayerById(dat.targets[1])
        local card = Fk:getCardById(card_id)
        if card.type == Card.TypeEquip then
          room:moveCardTo(card, Card.PlayerEquip, to, fk.ReasonPut, silun.name, "", true, player.id)
          if not to.dead then
            to:reset()
          end
        elseif card.sub_type == Card.SubtypeDelayedTrick then
          -- FIXME : deal with visual DelayedTrick
          room:moveCardTo(card, Card.PlayerJudge, to, fk.ReasonPut, silun.name, "", true, player.id)
        end
      else
        local drawPilePosition = 1
        if choice == "Bottom" then
          drawPilePosition = -1
        end
        room:moveCards({
          ids = {card_id},
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = silun.name,
          drawPilePosition = drawPilePosition,
          moveVisible = true
        })
      end
      if reset_self and not player.dead then
        player:reset()
      end
    end
  end
})

silun:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(silun.name)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:drawCards(4, silun.name)
    for i = 1, 4, 1 do
      if player.dead or player:isNude() then return end
      local _, dat = room:askToUseActiveSkill(player, {
        skill_name = "silun_active",
        prompt = "#silun-card:::" .. tostring(i),
        cancelable = false,
      })
      local card_id = dat and dat.cards[1] or player:getCardIds("he")[1]
      local choice = dat and dat.interaction or "Top"
      local reset_self = room:getCardArea(card_id) == Card.PlayerEquip
      if choice == "Field" then
        local to = room:getPlayerById(dat.targets[1])
        local card = Fk:getCardById(card_id)
        if card.type == Card.TypeEquip then
          room:moveCardTo(card, Card.PlayerEquip, to, fk.ReasonPut, silun.name, "", true, player.id)
          if not to.dead then
            to:reset()
          end
        elseif card.sub_type == Card.SubtypeDelayedTrick then
          -- FIXME : deal with visual DelayedTrick
          room:moveCardTo(card, Card.PlayerJudge, to, fk.ReasonPut, silun.name, "", true, player.id)
        end
      else
        local drawPilePosition = 1
        if choice == "Bottom" then
          drawPilePosition = -1
        end
        room:moveCards({
          ids = {card_id},
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = silun.name,
          drawPilePosition = drawPilePosition,
          moveVisible = true
        })
      end
      if reset_self and not player.dead then
        player:reset()
      end
    end
  end
})

return silun
