local heqia_active = fk.CreateSkill {
  name = "heqia_active",
}

Fk:loadTranslationTable{
  ["heqia_active"] = "和洽",
  ["heqia_give"] = "交给一名其他角色任意张牌",
  ["heqia_prey"] = "令一名角色将至少一张牌交给你",
}

heqia_active:addEffect("active", {
  min_card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local choices = {}
    if not player:isNude() then
      table.insert(choices, "heqia_give")
    end
    if table.find(Fk:currentRoom().alive_players, function(p)
      return player ~= p and not p:isNude()
    end) then
      table.insert(choices, "heqia_prey")
    end
    return UI.ComboBox {choices = choices, all_choices = {"heqia_give", "heqia_prey"}}
  end,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data == "heqia_prey" then
      return false
    else
      return true
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= player then
      if self.interaction.data == "heqia_prey" then
        return not to_select:isNude()
      else
        return selected_cards > 0
      end
    end
  end,
})

return heqia_active
