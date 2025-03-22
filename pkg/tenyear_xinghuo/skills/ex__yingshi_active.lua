local ex__yingshi_active = fk.CreateSkill {
  name = "ty_ex__yingshi_active"
}

Fk:loadTranslationTable {
  ["ty_ex__yingshi_active"] = "应势",
}

ex__yingshi_active:addEffect("active", {
  card_num = 1,
  target_num = 2,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return to_select ~= player
    elseif #selected == 1 then
      return true
    end
  end,
})

return ex__yingshi_active
