local ty_ex__yaoming_active = fk.CreateSkill {
  name = "ty_ex__yaoming_active"
}

Fk:loadTranslationTable{
  ['ty_ex__yaoming_active'] = '邀名',
  ['ty_ex__yaoming_throw'] = '弃置一名其他角色的一张手牌',
  ['ty_ex__yaoming_draw'] = '令一名其他角色摸一张牌',
  ['ty_ex__yaoming_recast'] = '令一名角色弃置至多两张牌再摸等量的牌',
}

ty_ex__yaoming_active:addEffect('active', {
  card_num = 0,
  target_num = 1,
  interaction = function()
    local all_choices = {"ty_ex__yaoming_throw", "ty_ex__yaoming_draw", "ty_ex__yaoming_recast" }
    local choices = table.filter(all_choices, function (c)
      return Self:getMark(c.."-turn") == 0
    end)
    return UI.ComboBox {choices = choices, all_choices = all_choices }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected ~= 0 then return false end
    local to = Fk:currentRoom():getPlayerById(to_select)
    if skill.interaction.data == "ty_ex__yaoming_throw" then
      return player.id ~= to_select and not to:isKongcheng()
    elseif skill.interaction.data == "ty_ex__yaoming_draw" then
      return player.id ~= to_select
    else
      return not to:isNude()
    end
  end,
})

return ty_ex__yaoming_active
