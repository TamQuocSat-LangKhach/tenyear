local zhangrong = fk.CreateSkill {
  name = "zhangrong_active"
}

Fk:loadTranslationTable{
  ['zhangrong_active'] = '掌戎',
  ['zhangrong1'] = '失去体力',
  ['zhangrong2'] = '弃置手牌',
}

zhangrong:addEffect('active', {
  name = "zhangrong_active",
  card_num = 0,
  min_target_num = 1,
  max_target_num = function(player)
    return player.hp
  end,
  interaction = function()
    return UI.ComboBox {choices = {"zhangrong1", "zhangrong2"}}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards, card)
    if #selected < player.hp then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if skill.interaction.data == "zhangrong1" then
        return target.hp >= player.hp
      elseif skill.interaction.data == "zhangrong2" then
        return target:getHandcardNum() >= player:getHandcardNum() and not target:isKongcheng()
      end
    end
  end,
})

return zhangrong
