local lianhuan = fk.CreateSkill {
  name = "jj__lianhuan&",
}

Fk:loadTranslationTable{
  ["jj__lianhuan&"] = "连环",
  [":jj__lianhuan&"] = "你可以将一张♣手牌当【铁索连环】使用或重铸（每回合限三次）。",
}

lianhuan:addEffect("active", {
  mute = true,
  prompt = "#lianhuan",
  card_num = 1,
  min_target_num = 0,
  times = function(self, player)
    return player.phase == Player.Play and 3 - player:usedSkillTimes(lianhuan.name, Player.HistoryTurn) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(lianhuan.name, Player.HistoryTurn) < 3
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Club and table.contains(player:getHandlyIds(), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards == 1 then
      local card = Fk:cloneCard("iron_chain")
      card:addSubcard(selected_cards[1])
      card.skillName = lianhuan.name
      return player:canUse(card) and card.skill:targetFilter(player, to_select, selected, selected_cards, card)
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if #selected_cards == 1 then
      if #selected == 0 then
        return table.contains(player:getCardIds("h"), selected_cards[1])
      else
        local card = Fk:cloneCard("iron_chain")
        card:addSubcard(selected_cards[1])
        card.skillName = lianhuan.name
        return card.skill:feasible(player, selected, {}, card)
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    player:broadcastSkillInvoke(lianhuan.name)
    if #effect.tos == 0 then
      room:notifySkillInvoked(player, lianhuan.name, "drawcard")
      room:recastCard(effect.cards, player, lianhuan.name)
    else
      room:notifySkillInvoked(player, lianhuan.name, "control")
      room:sortByAction(effect.tos)
      room:useVirtualCard("iron_chain", effect.cards, player, effect.tos, lianhuan.name)
    end
  end,
})

return lianhuan
