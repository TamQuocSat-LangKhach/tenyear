local bingji_viewas = fk.CreateSkill {
  name = "bingji_viewas",
}

Fk:loadTranslationTable{
  ["bingji_viewas"] = "秉纪",
}

local U = require "packages/utility/utility"

bingji_viewas:addEffect("active", {
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local all_choices = {"slash", "peach"}
    local choices = table.filter(all_choices, function(name)
      local card = Fk:cloneCard(name)
      card.skillName = "bingji"
      return not player:prohibitUse(card)
    end)
    return U.CardNameBox {choices = choices, all_choices = all_choices}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 and to_select ~= player then
      local card = Fk:cloneCard(self.interaction.data)
      card.skillName = "bingji"
        return player:canUseTo(card, to_select, {bypass_distances = false, bypass_times = true})
    end
  end,
})

return bingji_viewas
