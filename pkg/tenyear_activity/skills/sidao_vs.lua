local sidao_vs = fk.CreateSkill {
  name = "sidao_vs"
}

Fk:loadTranslationTable{
  ['sidao_vs'] = '伺盗',
  ['tanbei'] = '贪狈',
}

sidao_vs:addEffect('active', {
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and table.contains(player.player_cards[Player.Hand], to_select) then
      local c = Fk:cloneCard("snatch")
      c:addSubcard(to_select)
      c.skillName = "tanbei"
      return not player:prohibitUse(c)
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local to = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 and #selected_cards == 1 and table.contains(player.sidao_tos or {}, to_select) and not to:isAllNude() then
      local c = Fk:cloneCard("snatch")
      c:addSubcard(selected_cards[1])
      c.skillName = "tanbei"
      return not player:isProhibited(to, c)
    end
  end,
})

return sidao_vs
