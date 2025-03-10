local benyu = fk.CreateSkill {
  name = "ty__benyu_active"
}

Fk:loadTranslationTable{
  ['ty__benyu_active'] = '贲育',
  ['ty__benyu_damage'] = '弃牌并造成伤害',
  ['#ty__benyu-discard'] = '贲育：你可以弃置至少%arg牌，对 %dest 造成1点伤害',
  ['#ty__benyu-draw'] = '贲育：你可以摸至 %arg 张牌',
  ['ty__benyu_draw'] = '摸牌',
}

benyu:addEffect('active', {
  name = "ty__benyu_active",
  prompt = function (self, player)
    local to = self.ty__benyu_data[1]
    local x = self.ty__benyu_data[2]
    if self.interaction.data == "ty__benyu_damage" then
      return "#ty__benyu-discard::"..to..":"..(x+1)
    else
      return "#ty__benyu-draw:::"..math.min(5, x)
    end
  end,
  interaction = function(self, player)
    local all_choices = {"ty__benyu_draw", "ty__benyu_damage"}
    local choices = {}
    if player:getHandcardNum() < math.min(self.ty__benyu_data[2], 5) then
      table.insert(choices, all_choices[1])
    end
    if #player:getCardIds("he") > self.ty__benyu_data[2] then
      table.insert(choices, all_choices[2])
    end
    if #choices > 0 then
      return UI.ComboBox { choices = choices, all_choices = all_choices }
    end
  end,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return self.interaction.data == "ty__benyu_damage" and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  feasible = function(self, player, selected, selected_cards)
    if self.interaction.data == "ty__benyu_damage" then
      return #selected_cards > self.ty__benyu_data[2]
    end
    return #selected_cards == 0
  end,
})

return benyu
