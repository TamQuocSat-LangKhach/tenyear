local jiangchi_active = fk.CreateSkill {
  name = "ty_ex__jiangchi_active",
}

Fk:loadTranslationTable{
  ["ty_ex__jiangchi_active"] = "将驰",
  ["ty_ex__jiangchi_draw2"] = "摸两张牌，不能出【杀】",
  ["ty_ex__jiangchi_discard"] = "弃一张牌，【杀】无距离限制且次数+1",
}

jiangchi_active:addEffect("active", {
  interaction = function(self, player)
    local choices = {"ty_ex__jiangchi_draw2", "draw1"}
    if not player:isNude() then
      table.insert(choices, "ty_ex__jiangchi_discard")
    end
    return UI.ComboBox {
      choices = choices,
      all_choices = {"ty_ex__jiangchi_draw2", "draw1", "ty_ex__jiangchi_discard"},
    }
  end,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data ==  "ty_ex__jiangchi_discard" then
      return #selected == 0 and not player:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected == 0 then
      if self.interaction.data == "ty_ex__jiangchi_discard" then
        return #selected_cards == 1
      else
        return #selected_cards == 0
      end
    end
  end,
})

return jiangchi_active
