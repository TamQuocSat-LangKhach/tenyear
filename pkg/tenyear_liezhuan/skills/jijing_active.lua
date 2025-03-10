local jijing = fk.CreateSkill {
  name = "jijing"
}

Fk:loadTranslationTable{
  ['jijing_active'] = '吉境',
}

jijing:addEffect('active', {
  mute = true,
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if not player:prohibitDiscard(Fk:getCardById(to_select)) then
      local num = 0
      for _, id in ipairs(selected) do
        num = num + Fk:getCardById(id).number
      end
      return num + Fk:getCardById(to_select).number <= player:getMark("jijing-tmp")
    end
  end,
  feasible = function (skill, player, selected_cards)
    local num = 0
    for _, id in ipairs(selected_cards) do
      num = num + Fk:getCardById(id).number
    end
    return num == player:getMark("jijing-tmp")
  end,
})

return jijing
