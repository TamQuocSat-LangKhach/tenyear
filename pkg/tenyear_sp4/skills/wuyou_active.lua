local wuyou_active = fk.CreateSkill {
  name = "wuyou&"
}

Fk:loadTranslationTable{
  ['wuyou&'] = '武佑',
  ['#wuyou-other'] = '发动 武佑，选择一张牌交给一名拥有“武佑”的角色',
  ['wuyou'] = '武佑',
  [':wuyou&'] = '出牌阶段限一次，你可以将一张牌交给武关羽，然后其可以将一张牌交给你并声明一种基本牌或普通锦囊牌的牌名，此牌视为声明的牌。',
}

wuyou_active:addEffect('active', {
  anim_type = "support",
  prompt = "#wuyou-other",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local targetRecorded = player:getTableMark("wuyou_targets-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(wuyou) and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected, selected_cards, card, extra_data)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select):hasSkill(wuyou) and
      not table.contains(player:getTableMark("wuyou_targets-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.from)
    local player = room:getPlayerById(effect.tos[1])
    player:broadcastSkillInvoke("wuyou")
    room:addTableMarkIfNeed(target, "wuyou_targets-phase", player.id)
    room:moveCardTo(effect.cards, Player.Hand, player, fk.ReasonGive, skill.name, nil, false, target.id)
    if player.dead or player:isKongcheng() or target.dead then return end
    wuyou:onUse(room, {from = player.id, tos = { target.id } })
  end,
})

return wuyou_active
