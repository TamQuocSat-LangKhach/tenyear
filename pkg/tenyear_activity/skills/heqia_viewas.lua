local heqia = fk.CreateSkill {
  name = "heqia"
}

Fk:loadTranslationTable{
  ['heqia_viewas'] = '和洽',
  ['heqia'] = '和洽',
}

heqia:addEffect('active', {
  interaction = function()
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, "heqia", all_names)
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = function (skill, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(true), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if not skill.interaction.data or #selected_cards ~= 1 then return false end
    if #selected >= player:getMark("heqia-tmp") then return false end
    local to_use = Fk:cloneCard(skill.interaction.data)
    to_use.skillName = "heqia"
    if player:isProhibited(Fk:currentRoom():getPlayerById(to_select), to_use) then return false end
    return to_use.skill:modTargetFilter(player, to_select, selected, to_use, false)
  end,
  feasible = function(self, player, selected, selected_cards)
    if not skill.interaction.data or #selected_cards ~= 1 then return false end
    local to_use = Fk:cloneCard(skill.interaction.data)
    to_use.skillName = "heqia"
    if to_use.skill:getMinTargetNum() == 0 then
      return (#selected == 0 or table.contains(selected, player.id)) and to_use.skill:feasible(player, selected, selected_cards, to_use)
    else
      return #selected > 0
    end
  end,
})

return heqia
