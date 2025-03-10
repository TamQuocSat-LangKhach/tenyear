local faqi = fk.CreateSkill {
  name = "faqi",
}

Fk:loadTranslationTable{
  ['faqi_viewas'] = '法器',
  ['faqi'] = '法器',
}

faqi:addEffect('viewas', {
  interaction = function()
    local all_names = U.getAllCardNames("t")
    local names = U.getViewAsCardNames(Self, faqi.name, all_names, {}, Self:getTableMark(faqi.name .. "-turn"))
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = faqi.name
    return card
  end,
})

return faqi
