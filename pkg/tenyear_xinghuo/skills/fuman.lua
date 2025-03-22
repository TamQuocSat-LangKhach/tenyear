local fuman = fk.CreateSkill {
  name = "ty_ex__fuman",
}

Fk:loadTranslationTable{
  ["ty_ex__fuman"] = "抚蛮",
  [":ty_ex__fuman"] = "出牌阶段每名角色限一次，你可以弃置一张牌，令一名角色从弃牌堆中获得一张【杀】，然后其于其回合结束前失去此【杀】时，"..
  "其摸一张牌。若为因使用或打出而失去，你摸一张牌。",

  ["#ty_ex__fuman"] = "抚蛮：弃一张牌，令一名角色获得一张【杀】，其于其下个回合结束前失去时摸一张牌",
  ["@@ty_ex__fuman"] = "抚蛮",

  ["$ty_ex__fuman1"] = "蛮夷畏威，杀之积怨，抚之怀德。",
  ["$ty_ex__fuman2"] = "以威镇夷，宜抚之，勿戾之。",
}

fuman:addEffect("active", {
  name = "ty_ex__fuman",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#ty_ex__fuman",
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not table.contains(player:getTableMark("ty_ex__fuman-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "ty_ex__fuman-phase", target.id)
    room:throwCard(effect.cards, fuman.name, player, player)
    if target.dead then return end
    local card = room:getCardsFromPileByRule("slash", 1, "discardPile")
    if #card > 0 then
      room:addTableMark(target, fuman.name, {player.id, card[1]})
      room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonJustMove, fuman.name, nil, true, player, {"@@ty_ex__fuman", player.id})
    end
  end,
})

fuman:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player and not player:isKongcheng()
  end,
  on_refresh = function (self, event, target, player, data)
    for _, id in ipairs(player:getCardIds("h")) do
      player.room:setCardMark(Fk:getCardById(id), "@@ty_ex__fuman", 0)
    end
  end,
})

fuman:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.ty_ex__fuman and data.extra_data.ty_ex__fuman[player.id]
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(data.extra_data.ty_ex__fuman[player.id], fuman.name)
  end,

  can_refresh = function (self, event, target, player, data)
    if player.seat ~= 1 then return false end
    for _, move in ipairs(data) do
      if move.from then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@ty_ex__fuman") ~= 0 then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    data.extra_data = data.extra_data or {}
    data.extra_data.ty_ex__fuman = data.extra_data.ty_ex__fuman or {}
    for _, move in ipairs(data) do
      if move.from then
        for _, info in ipairs(move.moveInfo) do
          local owner = Fk:getCardById(info.cardId):getMark("@@ty_ex__fuman")
          if info.fromArea == Card.PlayerHand and owner ~= 0 then
            room:setCardMark(Fk:getCardById(info.cardId), "@@ty_ex__fuman", 0)
            data.extra_data.ty_ex__fuman[move.from.id] = (data.extra_data.ty_ex__fuman[move.from.id] or 0) + 1
            if move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResonpse then
              data.extra_data.ty_ex__fuman[owner] = (data.extra_data.ty_ex__fuman[owner] or 0) + 1
            end
          end
        end
      end
    end
  end,
})

return fuman
