local zifu_active = fk.CreateSkill {
  name = "ty__zifu_active",
}

Fk:loadTranslationTable{
  ["ty__zifu_active"] = "自缚",
}

zifu_active:addEffect("active", {
  card_num = function(self, player)
    local names = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(names, Fk:getCardById(id).trueName)
    end
    return #names
  end,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select) and
      table.every(selected, function(id)
        return Fk:getCardById(to_select).trueName ~= Fk:getCardById(id).trueName
      end)
  end,
})

return zifu_active
