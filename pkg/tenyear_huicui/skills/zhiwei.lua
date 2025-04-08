local zhiwei = fk.CreateSkill {
  name = "zhiwei",
}

Fk:loadTranslationTable{
  ["zhiwei"] = "至微",
  [":zhiwei"] = "游戏开始时，你选择一名其他角色：<br>该角色造成伤害后，你摸一张牌；<br>该角色受到伤害后，你随机弃置一张手牌；<br>"..
  "你弃牌阶段弃置的牌均被该角色获得。<br>准备阶段，若场上没有“至微”角色，你可以重新选择一名其他角色。",

  ["#zhiwei-choose"] = "至微：请选择“至微”角色",
  ["@zhiwei"] = "至微",

  ["$zhiwei1"] = "体信贯于神明，送终以礼。",
  ["$zhiwei2"] = "昭德以行，生不能侍奉二主。",
}

zhiwei:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhiwei.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      prompt = "#zhiwei-choose",
      skill_name = zhiwei.name,
      cancelable = false,
    })[1]
    room:setPlayerMark(player, zhiwei.name, to.id)
    room:setPlayerMark(player, "@zhiwei", to.general)
  end,
})

zhiwei:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhiwei.name) and player.phase == Player.Start and
      player:getMark(zhiwei.name) == 0 and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      prompt = "#zhiwei-choose",
      skill_name = zhiwei.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(player, zhiwei.name, to.id)
    room:setPlayerMark(player, "@zhiwei", to.general)
  end,
})

zhiwei:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhiwei.name) and target and player:getMark(zhiwei.name) == target.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@zhiwei", target.general)
    player:drawCards(1, zhiwei.name)
  end,
})

zhiwei:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhiwei.name) and player:getMark(zhiwei.name) == target.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@zhiwei", target.general)
    local cards = table.filter(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end)
    if #cards > 0 then
      room:throwCard(table.random(cards), zhiwei.name, player, player)
    end
  end,
})

zhiwei:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhiwei.name) and player.phase == Player.Discard and
      player:getMark(zhiwei.name) ~= 0 and not player.room:getPlayerById(player:getMark(zhiwei.name)).dead then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              table.contains(player.room.discard_pile, info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {player:getMark(zhiwei.name)}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark(zhiwei.name))
    local cards = {}
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            table.contains(room.discard_pile, info.cardId) then
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end
    if #cards > 0 then
      room:setPlayerMark(player, "@zhiwei", to.general)
      room:moveCards({
        ids = cards,
        to = to,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = zhiwei.name,
      })
    end
  end,
})

zhiwei:addEffect(fk.Deathed, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark(zhiwei.name) == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, zhiwei.name, 0)
    room:setPlayerMark(player, "@zhiwei", 0)
  end,
})

zhiwei:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, zhiwei.name, 0)
  room:setPlayerMark(player, "@zhiwei", 0)
end)

return zhiwei
