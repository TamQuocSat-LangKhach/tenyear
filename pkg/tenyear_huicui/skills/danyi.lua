local danyi = fk.CreateSkill {
  name = "danyi",
}

Fk:loadTranslationTable{
  ["danyi"] = "耽意",
  [":danyi"] = "你使用牌指定目标后，若此牌目标与你使用的上一张牌有相同的目标，你可以摸X张牌（X为这些目标的数量）。",

  ["$danyi1"] = "满城锦绣，何及笔下春秋？",
  ["$danyi2"] = "一心向学，不闻窗外风雨。",
}

danyi:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(danyi.name) and data.firstTarget then
      local room = player.room
      local use_event = room.logic:getCurrentEvent()
      local last_tos = {}
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.id < use_event.id then
          local use = e.data
          if use.from == player then
            last_tos = use.tos
            return true
          end
        end
      end, 0)
      if #last_tos == 0 then return false end
      local x = #table.filter(room.players, function (p)
        return table.contains(data.use.tos, p) and table.contains(last_tos, p)
      end)
      if x > 0 then
        event:setCostData(self, {choice = x})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self).choice, danyi.name)
  end,
})

return danyi
