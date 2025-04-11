local shenduan = fk.CreateSkill {
  name = "ty_ex__shenduan"
}

Fk:loadTranslationTable{
  ['ty_ex__shenduan_active'] = '慎断',
  ['ty_ex__shenduan'] = '慎断',
}

shenduan:addEffect('viewas', {
  expand_pile = function () return Self:getTableMark("ty_ex__shenduan") end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      local ids = player:getMark("ty_ex__shenduan")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("supply_shortage")
    c.skillName = shenduan.name
    c:addSubcard(cards[1])
    return c
  end,
})

return shenduan
