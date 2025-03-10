local shexue = fk.CreateSkill {
  name = "shexue",
}

Fk:loadTranslationTable{
  ['shexue_viewas'] = '设学',
  ['shexue'] = '设学',
}

shexue:addEffect('viewas', {
  interaction = function(skill)
    return UI.ComboBox {choices = skill.virtualuse_names, all_choices = skill.virtualuse_allnames }
  end,
  card_filter = function (skill, player, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not skill.interaction.data then return end
    local card = Fk:cloneCard(skill.interaction.data)
    card:addSubcards(cards)
    card.skillName = "shexue"
    return card
  end,
})

return shexue
