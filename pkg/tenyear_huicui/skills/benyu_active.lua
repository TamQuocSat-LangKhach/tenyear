local benyu_active = fk.CreateSkill {
  name = "ty__benyu_active",
}

Fk:loadTranslationTable{
  ["ty__benyu_active"] = "贲育",
  ["ty__benyu_damage"] = "弃置至少%arg张牌，对 %dest 造成1点伤害",
  ["ty__benyu_draw"] = "将手牌摸至%arg张",
}

benyu_active:addEffect("active", {
  name = "ty__benyu_active",
  interaction = function(self, player)
    local from = Fk:currentRoom():getPlayerById(self.ty__benyu)
    local all_choices, choices = {}, {}
    local n1 = math.min(from:getHandcardNum(), 5)
    local n2 = from:getHandcardNum() + 1
    table.insert(all_choices, "ty__benyu_draw:::"..n1)
    if player:getHandcardNum() < n1 then
      table.insert(choices, "ty__benyu_draw:::"..n1)
    end
    table.insert(all_choices, "ty__benyu_damage::"..from.id..":"..n2)
    if #player:getCardIds("he") >= n2 then
      table.insert(choices, "ty__benyu_damage::"..from.id..":"..n2)
    end
    if #choices == 0 then return end
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data:startsWith("ty__benyu_damage") then
      return not player:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if self.interaction.data:startsWith("ty__benyu_damage") then
      return #selected_cards > Fk:currentRoom():getPlayerById(self.ty__benyu):getHandcardNum()
    else
      return #selected_cards == 0
    end
  end,
})

return benyu_active
