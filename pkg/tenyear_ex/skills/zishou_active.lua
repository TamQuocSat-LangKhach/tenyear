local zishou_active = fk.CreateSkill {
  name = "ty_ex__zishou_active",
}

Fk:loadTranslationTable{
  ["ty_ex__zishou_active"] = "自守",
}

zishou_active:addEffect("active", {
  min_card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select) and
      Fk:getCardById(to_select).suit ~= Card.NoSuit then
      if #selected == 0 then
        return true
      else
        return table.every(selected, function(id)
          return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id), true)
        end)
      end
    end
  end,
})

return zishou_active
