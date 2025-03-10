local ty__zifu_filter = fk.CreateSkill {
  name = "ty__zifu_filter"
}

Fk:loadTranslationTable{
  ['ty__zifu_filter'] = '自缚',
}

ty__zifu_filter:addEffect('active', {
  target_num = 0,
  card_num = function(self, player)
    local names = {}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      table.insertIfNeed(names, Fk:getCardById(id).trueName)
    end
    return #names
  end,
  card_filter = function(self, player, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Hand then return false end
    local name = Fk:getCardById(to_select).trueName
    return table.every(selected, function(id)
      return name ~= Fk:getCardById(id).trueName
    end)
  end,
  target_filter = Util.FalseFunc,
  can_use = Util.FalseFunc,
})

return ty__zifu_filter
