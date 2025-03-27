local jj__lianhuan = fk.CreateSkill {
  name = "jj__lianhuan&"
}

Fk:loadTranslationTable{
  ['jj__lianhuan&'] = '连环',
  [':jj__lianhuan&'] = '你可以将一张梅花手牌当【铁索连环】使用或重铸（每回合限三次）。',
}

jj__lianhuan:addEffect('active', {
  card_num = 1,
  min_target_num = 0,
  times = function(self)
    return self.player.phase == Player.Play and 3 - self.player:usedSkillTimes(jj__lianhuan.name, Player.HistoryTurn) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(jj__lianhuan.name, Player.HistoryTurn) < 3
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Club and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards == 1 then
      local card = Fk:cloneCard("iron_chain")
      card:addSubcard(selected_cards[1])
      return card.skill:canUse(player, card) and card.skill:targetFilter(to_select, selected, selected_cards, card, nil, player) and
        not player:prohibitUse(card) and not player:isProhibited(Fk:currentRoom():getPlayerById(to_select), card)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if #effect.tos == 0 then
      room:recastCard(effect.cards, player, jj__lianhuan.name)
    else
      room:sortPlayersByAction(effect.tos)
      room:useVirtualCard("iron_chain", effect.cards, player, table.map(effect.tos, Util.Id2PlayerMapper), jj__lianhuan.name)
    end
  end,
})

return jj__lianhuan
