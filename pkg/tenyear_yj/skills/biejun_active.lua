local biejun_active = fk.CreateSkill {
  name = "biejun&",
}

Fk:loadTranslationTable{
  ["biejun&"] = "别君",
  [":biejun&"] = "出牌阶段限一次，你可以将一张手牌交给李婉。当李婉受到伤害时，若其手牌中没有本回合以此法获得的牌，其可以翻面并防止此伤害。",

  ["#biejun&"] = "别君：选择一张手牌交给一名拥有“别君”的角色",
}

biejun_active:addEffect("active", {
  anim_type = "support",
  prompt = "#biejun&",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local targetRecorded = player:getTableMark("biejun_targets-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill("biejun") and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:hasSkill("biejun") and
      not table.contains(player:getTableMark("biejun_targets-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    target:broadcastSkillInvoke("biejun")
    room:addTableMark(player, "biejun_targets-phase", target.id)
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, "biejun", nil, false, player, "@@biejun-inhand-turn")
  end,
})

return biejun_active
