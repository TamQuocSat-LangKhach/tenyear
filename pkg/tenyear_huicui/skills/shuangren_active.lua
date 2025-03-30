local shuangren_active = fk.CreateSkill {
  name = "ty__shuangren_active",
}

Fk:loadTranslationTable{
  ["ty__shuangren_active"] = "双刃",
}

shuangren_active:addEffect("active", {
  card_num = 0,
  card_filter = Util.FalseFunc,
  min_target_num = 1,
  max_target_num = 2,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected < 2 then
      local to = Fk:currentRoom():getPlayerById(self.ty__shuangren)
      return to.kingdom == to_select.kingdom
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards == 0 and #selected > 0 and #selected <= 2 then
      return #selected == 1 or table.contains(table.map(selected, Util.IdMapper), self.ty__shuangren)
    end
  end,
})

return shuangren_active
