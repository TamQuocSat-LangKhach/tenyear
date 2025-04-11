local ty_ex__jiangchi_active = fk.CreateSkill {
  name = "ty_ex__jiangchi_active"
}

Fk:loadTranslationTable{
  ['ty_ex__jiangchi_active'] = '将驰',
  ['ty_ex__jiangchi_prohibit-phase'] = '摸两张牌，不能出【杀】',
  ['ty_ex__jiangchi_draw'] = '摸一张牌',
  ['ty_ex__jiangchi_targetmod-phase'] = '弃一张牌，【杀】无距离限制且次数+1',
}

ty_ex__jiangchi_active:addEffect('active', {
  interaction = function()
    local choices = {"ty_ex__jiangchi_prohibit-phase", "ty_ex__jiangchi_draw"}
    if not Self:isNude() then
      table.insert(choices, "ty_ex__jiangchi_targetmod-phase")
    end
    return UI.ComboBox {choices = choices}
  end,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return skill.interaction.data == "ty_ex__jiangchi_targetmod-phase" and #selected == 0 and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected == 0 then
      if skill.interaction.data == "ty_ex__jiangchi_targetmod-phase" then
        return #selected_cards == 1
      else
        return #selected_cards == 0
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local mark = skill.interaction.data
    if mark:endsWith("-phase") then
      room:setPlayerMark(player, "@@"..mark, 1)
    end
  end,
})

return ty_ex__jiangchi_active
