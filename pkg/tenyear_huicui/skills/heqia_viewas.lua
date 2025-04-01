local heqia_viewas = fk.CreateSkill {
  name = "heqia_viewas",
}

Fk:loadTranslationTable{
  ["heqia_viewas"] = "和洽",
}

local U = require "packages/utility/utility"

heqia_viewas:addEffect("active", {
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames("heqia", all_names)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  handly_pile = true,
  card_filter = function (skill, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(true), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if not self.interaction.data or #selected_cards ~= 1 then return end
    if #selected < self.heqia_num then
      local card = Fk:cloneCard(self.interaction.data)
      card.skillName = "heqia"
      card:addSubcards(selected_cards)
      if #selected == 0 then
        return card.skill:targetFilter(player, to_select, {}, {}, card, {bypass_distances = true, bypass_times = true})
      else
        return card.skill:modTargetFilter(player, to_select, selected, card, {bypass_distances = true, bypass_times = true})
      end
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if not self.interaction.data or #selected_cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "heqia"
    card:addSubcards(selected_cards)
    if card.skill:getMinTargetNum(player) == 0 then
      return (#selected == 0 or table.contains(selected, player)) and
        card.skill:feasible(player, selected, {}, card)
    else
      return #selected > 0
    end
  end,
})

return heqia_viewas
