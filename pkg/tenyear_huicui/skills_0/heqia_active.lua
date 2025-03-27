local heqia = fk.CreateSkill {
  name = "heqia_active"
}

Fk:loadTranslationTable{
  ['heqia_active'] = '和洽',
  ['heqia_give'] = '交给一名其他角色至少一张牌',
  ['heqia_prey'] = '令一名角色将至少一张牌交给你',
}

heqia:addEffect('active', {
  min_card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local choices = {}
    if not player:isNude() then table.insert(choices, "heqia_give") end
    if table.find(Fk:currentRoom().alive_players, function(p) return player ~= p and not p:isNude() end) then
      table.insert(choices, "heqia_prey")
    end
    return UI.ComboBox {choices = choices}
  end,
  card_filter = function(self, player, to_select, selected)
    if not skill.interaction.data or skill.interaction.data == "heqia_prey" then return false end
    return true
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local target_player = Fk:currentRoom():getPlayerById(to_select)
    if not skill.interaction.data or #selected > 0 or to_select == player.id then return false end
    if skill.interaction.data == "heqia_give" then
      return #selected_cards > 0
    else
      return not target_player:isNude()
    end
  end,
})

return heqia
