local zhiwei = fk.CreateSkill {
  name = "zhiwei"
}

Fk:loadTranslationTable{
  ['zhiwei'] = '至微',
  ['#zhiwei-choose'] = '至微：选择一名其他角色',
  ['@zhiwei'] = '至微',
  [':zhiwei'] = '游戏开始时，你选择一名其他角色，该角色造成伤害后，你摸一张牌；该角色受到伤害后，你随机弃置一张手牌。你弃牌阶段弃置的牌均被该角色获得。准备阶段，若场上没有“至微”角色，你可以重新选择一名其他角色。',
  ['$zhiwei1'] = '体信贯于神明，送终以礼。',
  ['$zhiwei2'] = '昭德以行，生不能侍奉二主。',
}

-- GameStart
zhiwei:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhiwei.name) then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    if #targets == 0 then return false end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#zhiwei-choose",
      skill_name = zhiwei.name,
      cancelable = false,
      no_indicate = true
    })
    if #to > 0 then
      room:setPlayerMark(player, zhiwei.name, to[1].id)
    end
  end,
})

-- TurnStart
zhiwei:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhiwei.name) then
      return player == target and player:getMark(zhiwei.name) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#zhiwei-choose",
      skill_name = zhiwei.name,
      cancelable = true,
      no_indicate = true
    })
    if #to > 0 then
      event:setCostData(skill, to[1].id)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, zhiwei.name, "special")
    player:broadcastSkillInvoke(zhiwei.name)
    room:setPlayerMark(player, zhiwei.name, event:getCostData(skill))
  end,
})

-- AfterCardsMove
zhiwei:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhiwei.name) then
      if player.phase ~= Player.Discard then return false end
      local zhiwei_id = player:getMark(zhiwei.name)
      if zhiwei_id == 0 then return false end
      local room = player.room
      local to = room:getPlayerById(zhiwei_id)
      if to == nil or to.dead then return false end
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              room:getCardArea(info.cardId) == Card.DiscardPile then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local zhiwei_id = player:getMark(zhiwei.name)
    if zhiwei_id == 0 then return false end
    local to = player.room:getPlayerById(zhiwei_id)
    if to == nil or to.dead then return false end
    local cards = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            player.room:getCardArea(info.cardId) == Card.DiscardPile then
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end
    if #cards > 0 then
      player.room:notifySkillInvoked(player, zhiwei.name, "support")
      player:broadcastSkillInvoke(zhiwei.name)
      player.room:setPlayerMark(player, "@zhiwei", to.general)
      player.room:moveCards({
        ids = cards,
        to = zhiwei_id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = zhiwei.name,
      })
    end
  end,
})

-- Damage and Damaged
zhiwei:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhiwei.name) then
      return target ~= nil and not target.dead and player:getMark(zhiwei.name) == target.id
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, zhiwei.name, "drawcard")
    player:broadcastSkillInvoke(zhiwei.name)
    room:setPlayerMark(player, "@zhiwei", target.general)
    room:drawCards(player, 1, zhiwei.name)
  end,
})

zhiwei:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhiwei.name) then
      return target ~= nil and not target.dead and player:getMark(zhiwei.name) == target.id and not player:isKongcheng()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Hand)
    if #cards > 0 then
      room:notifySkillInvoked(player, zhiwei.name, "negative")
      player:broadcastSkillInvoke(zhiwei.name)
      room:setPlayerMark(player, "@zhiwei", target.general)
      room:throwCard(table.random(cards, 1), zhiwei.name, player, player)
    end
  end,
})

-- BuryVictim
zhiwei:addEffect(fk.BuryVictim, {
  can_trigger = function(self, event, target, player, data)
    return player:getMark(zhiwei.name) == target.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, zhiwei.name, 0)
    room:setPlayerMark(player, "@zhiwei", 0)
  end,
})

return zhiwei
