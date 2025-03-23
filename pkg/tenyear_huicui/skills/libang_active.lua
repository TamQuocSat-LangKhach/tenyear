local libang = fk.CreateSkill {
  name = "libang"
}

Fk:loadTranslationTable{
  ['libang'] = '利傍',
}

libang:addEffect('active', {
  card_num = 2,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and table.contains(player.room:getTag('targets'):toStringList(), to_select:objectName()) and #selected_cards == 2
  end,
})

libang:onCost(function(self, room, effect)
  local from = effect.from
  local cards = room:askToCards(from, {
    min_num = 1,
    max_num = 2,
    include_equip = false,
    skill_name = self.name,
    cancelable = true,
  })

  if #cards < 2 then
    return false
  end

  effect.selected_cards = cards
  return true
end)

libang:onEffect(function(self, room, effect)
  local from = effect.from
  local targets = room:askToChoosePlayers(from, {
    min_num = 1,
    max_num = 1,
    skill_name = self.name,
    cancelable = true,
    targets = function(player)
      return player.room:getTag('targets'):toStringList()
    end,
  })

  if #targets == 0 then
    return false
  end

  local to = targets[1]
  room:moveCardTo(effect.selected_cards, from, to, Place.Hand, Reason.ActiveSkill)
end)

return libang
