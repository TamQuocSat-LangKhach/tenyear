local zhenze_active = fk.CreateSkill {
  name = "zhenze_active",
}

Fk:loadTranslationTable{
  ["zhenze_active"] = "震泽",
}

zhenze_active:addEffect("active", {
  card_num = 0,
  target_num = 0,
  interaction = UI.ComboBox {choices = {"zhenze_lose", "zhenze_recover"}},
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    local a = player:getHandcardNum() - player.hp
    local b = to_select:getHandcardNum() - to_select.hp
    if self.interaction.data == "zhenze_lose" then
      if a * b <= 0 and a ~= b then
        return { {content = "lose_hp", type = "warning"} }
      end
    else
      if a * b > 0 or a == b then
        return { {content = "heal_hp", type = "normal"} }
      end
    end
  end,
})

return zhenze_active
