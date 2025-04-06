local shexue_viewas = fk.CreateSkill {
  name = "shexue_viewas",
}

Fk:loadTranslationTable{
  ["shexue_viewas"] = "设学",
}

local U = require "packages/utility/utility"

shexue_viewas:addEffect("viewas", {
  interaction = function(self, player)
    local all_names = self.all_names
    local names = player:getViewAsCardNames("shexue", all_names, nil, nil, {bypass_distances = true, bypass_times = true})
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = function (skill, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = "shexue"
    return card
  end,
})

return shexue_viewas
