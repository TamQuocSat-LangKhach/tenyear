local jijing_active = fk.CreateSkill {
  name = "jijing_active"
}

Fk:loadTranslationTable{
  ["jijing_active"] = "吉境",
}

jijing_active:addEffect("active", {
  mute = true,
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if not player:prohibitDiscard(to_select) then
      local num = 0
      for _, id in ipairs(selected) do
        num = num + Fk:getCardById(id).number
      end
      return num + Fk:getCardById(to_select).number <= self.jijing_number
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    local num = 0
    for _, id in ipairs(selected_cards) do
      num = num + Fk:getCardById(id).number
    end
    return num == self.jijing_number
  end,
})

return jijing_active
