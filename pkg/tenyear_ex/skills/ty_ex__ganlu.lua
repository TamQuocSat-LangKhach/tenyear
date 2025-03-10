local ty_ex__ganlu = fk.CreateSkill {
  name = "ty_ex__ganlu"
}

Fk:loadTranslationTable{
  ['ty_ex__ganlu'] = '甘露',
  ['#ty_ex__ganlu-discard'] = '甘露: 请弃置两张手牌',
  [':ty_ex__ganlu'] = '出牌阶段限一次，你可以选择两名角色，交换其装备区内的所有牌，然后若其装备区牌数之差大于X，你需弃置两张手牌（X为你已损失体力值）。',
  ['$ty_ex__ganlu1'] = '纳采问名，而后交换文定。',
  ['$ty_ex__ganlu2'] = '兵戈相向，何如化戈为帛？',
}

ty_ex__ganlu:addEffect('active', {
  anim_type = "control",
  target_num = 2,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__ganlu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      local target1 = Fk:currentRoom():getPlayerById(to_select)
      local target2 = Fk:currentRoom():getPlayerById(selected[1])
      if #target1:getCardIds("e") == 0 and #target2:getCardIds("e") == 0 then
        return false
      end
      return true
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local target1 = Fk:currentRoom():getPlayerById(effect.tos[1])
    local target2 = Fk:currentRoom():getPlayerById(effect.tos[2])
    local cards1 = table.clone(target1:getCardIds("e"))
    local cards2 = table.clone(target2:getCardIds("e"))
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = effect.tos[1],
        ids = cards1,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = effect.from,
        skillName = ty_ex__ganlu.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = effect.tos[2],
        ids = cards2,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = effect.from,
        skillName = ty_ex__ganlu.name,
      })
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end

    moveInfos = {}

    if not target2.dead then
      local to_ex_cards1 = table.filter(cards1, function (id)
        return room:getCardArea(id) == Card.Processing and target2:getEquipment(Fk:getCardById(id).sub_type) == nil
      end)
      if #to_ex_cards1 > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards1,
          fromArea = Card.Processing,
          to = effect.tos[2],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonExchange,
          proposer = effect.from,
          skillName = ty_ex__ganlu.name,
        })
      end
    end
    if not target1.dead then
      local to_ex_cards = table.filter(cards2, function (id)
        return room:getCardArea(id) == Card.Processing and target1:getEquipment(Fk:getCardById(id).sub_type) == nil
      end)
      if #to_ex_cards > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards,
          fromArea = Card.Processing,
          to = effect.tos[1],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonExchange,
          proposer = effect.from,
          skillName = ty_ex__ganlu.name,
        })
      end
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end

    table.insertTable(cards1, cards2)

    local dis_cards = table.filter(cards1, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #dis_cards > 0 then
      room:moveCardTo(dis_cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, ty_ex__ganlu.name)
    end

    local player = room:getPlayerById(effect.from)
    if math.abs(#target1:getCardIds("e") - #target2:getCardIds("e")) > player:getLostHp() then
      if player:getHandcardNum() > 2 then
        room:askToDiscard(player, {
          min_num = 2,
          max_num = 2,
          include_equip = false,
          skill_name = ty_ex__ganlu.name,
          cancelable = false,
          prompt = "#ty_ex__ganlu-discard",
        })
      else
        player:throwAllCards("h")
      end
    end
  end,
})

return ty_ex__ganlu
