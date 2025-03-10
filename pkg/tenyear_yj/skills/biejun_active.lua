local biejun = fk.CreateSkill {
  name = "biejun"
}

Fk:loadTranslationTable{
  ['biejun&'] = '别君',
  ['#biejun-active'] = '别君：选择一张手牌交给一名拥有“别君”的角色',
  ['biejun'] = '别君',
  ['@@biejun-inhand-turn'] = '别君',
  [':biejun&'] = '出牌阶段限一次，你可以将一张手牌交给李婉。',
}

biejun:addEffect('active', {
  anim_type = "support",
  prompt = "#biejun-active",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local targetRecorded = player:getTableMark("biejun_targets-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(biejun) and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select):hasSkill(biejun) and
      not table.contains(player:getTableMark("biejun_targets-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:broadcastSkillInvoke(biejun.name)
    room:addTableMark(player, "biejun_targets-phase", target.id)
    room:moveCardTo(effect.cards[1], Card.PlayerHand, target, fk.ReasonGive, biejun.name, nil, false, player.id, "@@biejun-inhand-turn")
  end,
})

return biejun
