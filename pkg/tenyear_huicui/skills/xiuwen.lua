local xiuwen = fk.CreateSkill {
  name = "xiuwen",
}

Fk:loadTranslationTable{
  ["xiuwen"] = "修文",
  [":xiuwen"] = "你使用一张牌时，若此牌名是你本局游戏第一次使用，你摸一张牌。",

  ["$xiuwen1"] = "书生笔下三尺剑，毫锋可杀人。",
  ["$xiuwen2"] = "吾以书执剑，可斩世间魍魉。",
}

xiuwen:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiuwen.name) and
      data.extra_data and data.extra_data.xiuwen
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, xiuwen.name)
  end,

  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(xiuwen.name, true) and
      not table.contains(player:getTableMark(xiuwen.name), data.card.trueName)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:addTableMark(player, xiuwen.name, data.card.trueName)
    data.extra_data = data.extra_data or {}
    data.extra_data.xiuwen = true
  end,
})

xiuwen:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, xiuwen.name, 0)
end)

return xiuwen
