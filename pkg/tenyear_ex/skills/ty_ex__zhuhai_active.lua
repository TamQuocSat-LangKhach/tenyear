local ty_ex__zhuhai = fk.CreateSkill {
  name = "ty_ex__zhuhai"
}

Fk:loadTranslationTable{
  ['ty_ex__zhuhai_active'] = '诛害',
  ['ty_ex__zhuhai'] = '诛害',
}

ty_ex__zhuhai:addEffect('active', {
  anim_type = "offensive",
  card_num = 1,
  target_num = 0,
  interaction = function()
    return UI.ComboBox {choices = {"slash", "dismantlement"} }
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip then
      local card = Fk:cloneCard(skill.interaction.data)
      card:addSubcard(to_select)
      card.skillName = "ty_ex__zhuhai"
      local to = Fk:currentRoom():getPlayerById(skill.ty_ex__zhuhai_victim)
      return not player:prohibitUse(card) and not player:isProhibited(to, card)
        and card.skill:modTargetFilter(to.id, {}, player, card, false)
    end
  end,
})

return ty_ex__zhuhai
