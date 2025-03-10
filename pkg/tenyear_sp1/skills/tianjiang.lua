local tianjiang = fk.CreateSkill {
  name = "tianjiang"
}

Fk:loadTranslationTable{
  ['tianjiang'] = '天匠',
  ['#tianjiang_trigger'] = '天匠',
  [':tianjiang'] = '游戏开始时，将牌堆中随机两张不同副类别的装备牌置入你的装备区。出牌阶段，你可以将装备区里的一张牌移动至其他角色的装备区（可替换原装备），若你移动的是〖铸刃〗打造的装备，你摸两张牌。',
  ['$tianjiang1'] = '巧夺天工，超凡脱俗。',
  ['$tianjiang2'] = '天赐匠法，精心锤炼。',
}

-- Active Skill
tianjiang:addEffect('active', {
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return #player.player_cards[Player.Equip] > 0
  end,
  card_filter = function(self, player, to_select, selected, targets)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip
  end,
  target_filter = function(self, player, to_select, selected, cards)
    if #selected == 0 and #cards == 1 and to_select ~= player.id then
      return #Fk:currentRoom():getPlayerById(to_select):getAvailableEquipSlots(Fk:getCardById(cards[1]).sub_type) > 0
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:getCardById(effect.cards[1])
    room:moveCardIntoEquip(target, card.id, tianjiang.name, true, player)
    if table.contains({"red_spear", "quenched_blade", "poisonous_dagger", "water_sword", "thunder_blade"}, card.name) then
      player:drawCards(2, tianjiang.name)
    end
  end,
})

-- Trigger Skill
tianjiang:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tianjiang.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("tianjiang")
    local equipMap = {}
    for _, id in ipairs(room.draw_pile) do
      local sub_type = Fk:getCardById(id).sub_type
      if Fk:getCardById(id).type == Card.TypeEquip and player:hasEmptyEquipSlot(sub_type) then
        local list = equipMap[tostring(sub_type)] or {}
        table.insert(list, id)
        equipMap[tostring(sub_type)] = list
      end
    end

    local put = U.getRandomCards(equipMap, 2)
    if #put > 0 then
      room:moveCardIntoEquip(player, put, tianjiang.name, false, player)
    end
  end,
})

return tianjiang
