local zhuiji = fk.CreateSkill {
  name = "ty__zhuijix",
}

Fk:loadTranslationTable{
  ["ty__zhuijix"] = "追姬",
  [":ty__zhuijix"] = "当你死亡后，你可以令一名角色从牌堆和弃牌堆中随机使用有空余栏位的装备牌，直至其装备区满，若如此做，"..
  "当其失去以此法使用的装备牌后，废除对应的装备栏。",

  ["#ty__zhuijix-choose"] = "追姬：你可以令一名角色随机使用装备牌至装备区满",

  ["$ty__zhuijix1"] = "此生与君相遇，足以含笑九泉。",
  ["$ty__zhuijix2"] = "夫君珍重，万望保重身体。",
}

zhuiji:addEffect(fk.Deathed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuiji.name, false, true) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:hasEmptyEquipSlot()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:hasEmptyEquipSlot()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__zhuijix-choose",
      skill_name = zhuiji.name,
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
    local subtypes = {
      Card.SubtypeWeapon,
      Card.SubtypeArmor,
      Card.SubtypeDefensiveRide,
      Card.SubtypeOffensiveRide,
      Card.SubtypeTreasure
    }
    local subtype
    while not to.dead do
      while #subtypes > 0 do
        subtype = table.remove(subtypes, 1)
        if to:hasEmptyEquipSlot(subtype) then
          local cards = {}
          local card
          cards = table.filter(room.draw_pile, function(id)
            card = Fk:getCardById(id)
            return card.sub_type == subtype and to:canUseTo(card, to)
          end)
          for _, id in ipairs(room.discard_pile) do
            card = Fk:getCardById(id)
            if card.sub_type == subtype and to:canUseTo(card, to) then
              table.insert(cards, id)
            end
          end
          if #cards > 0 then
            card = cards[math.random(1, #cards)]
            room:addTableMark(to, zhuiji.name, card)
            room:useCard{
              from = to,
              tos = {to},
              card = Fk:getCardById(card),
            }
            break
          end
        end
      end
      if #subtypes == 0 then break end
    end
  end,
})

zhuiji:addEffect(fk.AfterCardsMove, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark(zhuiji.name) ~= 0 and not player.dead then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and table.contains(player:getTableMark("ty__zhuijix"), info.cardId) and
              #player:getAvailableEquipSlots(Fk:getCardById(info.cardId).sub_type) > 0 then
              local e = player.room.logic:getCurrentEvent():findParent(GameEvent.SkillEffect)
              if e and e.data.skill == self then  --FIXME：防止顶替装备时重复触发
                return false
              end
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(event.data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and table.contains(player:getTableMark(zhuiji.name), info.cardId) and
            #player:getAvailableEquipSlots(Fk:getCardById(info.cardId).sub_type) > 0 then
            room:removeTableMark(player, zhuiji.name, info.cardId)
            room:abortPlayerArea(player, {Util.convertSubtypeAndEquipSlot(Fk:getCardById(info.cardId).sub_type)})
          end
        end
      end
    end
  end,
})

return zhuiji
