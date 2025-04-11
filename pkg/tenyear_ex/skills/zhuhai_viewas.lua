local zhuhai_viewas = fk.CreateSkill {
  name = "ty_ex__zhuhai_viewas"
}

Fk:loadTranslationTable{
  ["ty_ex__zhuhai_viewas"] = "诛害",
}

local U = require "packages/utility/utility"

zhuhai_viewas:addEffect("viewas", {
  interaction = function(self, player)
    local all_names = {"slash", "dismantlement"}
    local names = player:getViewAsCardNames("ty_ex__zhuhai", all_names)
    if #names == 0 then return end
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = "ty_ex__zhuhai"
    return card
  end,
})

return zhuhai_viewas
