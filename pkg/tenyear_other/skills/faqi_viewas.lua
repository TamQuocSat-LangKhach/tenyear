local faqi = fk.CreateSkill {
  name = "faqi_viewas",
}

Fk:loadTranslationTable{
  ["faqi_viewas"] = "法器",
}

local U = require "packages/utility/utility"

faqi:addEffect("viewas", {
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("t")
    local names = player:getViewAsCardNames(faqi.name, Fk:getAllCardNames("t"), nil, player:getTableMark("faqi-turn"))
    if #names == 0 then return end
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "faqi"
    return card
  end,
})

return faqi
