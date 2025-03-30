local sidao_viewas = fk.CreateSkill {
  name = "sidao_viewas"
}

Fk:loadTranslationTable{
  ["sidao_viewas"] = "伺盗",
}

sidao_viewas:addEffect("viewas", {
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function (self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("snatch")
    c.skillName = "sidao"
    c:addSubcard(cards[1])
    return c
  end,
})

return sidao_viewas
