local zhangrong = fk.CreateSkill {
  name = "zhangrong_active",
}

Fk:loadTranslationTable{
  ["zhangrong_active"] = "掌戎",
}

zhangrong:addEffect("active", {
  card_num = 0,
  min_target_num = 1,
  max_target_num = function(self, player)
    return player.hp
  end,
  interaction = UI.ComboBox {choices = {"zhangrong1", "zhangrong2"}},
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected < player.hp then
      if self.interaction.data == "zhangrong1" then
        return to_select.hp >= player.hp
      elseif self.interaction.data == "zhangrong2" then
        return to_select:getHandcardNum() >= player:getHandcardNum() and not to_select:isKongcheng()
      end
    end
  end,
})

return zhangrong
