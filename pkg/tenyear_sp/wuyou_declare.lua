local wuyou_declare = fk.CreateSkill {
  name = "wuyou_declare"
}

Fk:loadTranslationTable{
  ['wuyou_declare'] = '武佑',
  ['wuyou'] = '武佑',
}

wuyou_declare:addEffect('active', {
  card_num = 1,
  target_num = 0,
  interaction = function(skill)
    return U.CardNameBox {
      choices = skill.interaction_choices,
      default_choice = "wuyou"
    }
  end,
  can_use = Util.FalseFunc,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk.all_card_types[skill.interaction.data] ~= nil and
      Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
})

return wuyou_declare
