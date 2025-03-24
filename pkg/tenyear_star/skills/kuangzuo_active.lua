local kuangzuo_active = fk.CreateSkill {
  name = "kuangzuo_active",
}

Fk:loadTranslationTable{
  ["kuangzuo_active"] = "匡祚",
}

kuangzuo_active:addEffect("active", {
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select).suit ~= Card.NoSuit and
      table.every(selected, function(id)
        return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id), true)
      end)
  end,
  feasible = function (skill, player, selected_cards)
    local suits = {}
    for _, id in ipairs(player:getCardIds("he")) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    table.removeOne(suits, Card.NoSuit)
    return #selected_cards == #suits
  end,
})

return kuangzuo_active
