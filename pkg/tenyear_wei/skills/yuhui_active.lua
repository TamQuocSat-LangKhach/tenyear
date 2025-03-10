local yuhui = fk.CreateSkill {
  name = "yuhui_active"
}

Fk:loadTranslationTable{
  ['yuhui_active'] = '斡衡',
  ['woheng_draw'] = '摸牌',
  ['woheng_discard'] = '弃牌',
}

yuhui:addEffect('active', {
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = { "woheng_draw", "woheng_discard" } }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected > 0 or not skill.interaction.data then return end
    if skill.interaction.data == "woheng_draw" then
      return true
    elseif skill.interaction.data == "woheng_discard" then
      if to_select == player.id then
        return table.find(player:getCardIds("he"), function (id)
          return not player:prohibitDiscard(id)
        end)
      else
        return not Fk:currentRoom():getPlayerById(to_select):isNude()
      end
    end
  end,
})

return yuhui
