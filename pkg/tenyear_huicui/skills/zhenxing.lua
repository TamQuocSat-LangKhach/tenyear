local zhenxing = fk.CreateSkill{
  name = "zhenxing",
}

Fk:loadTranslationTable{
  ["zhenxing"] = "镇行",
  [":zhenxing"] = "结束阶段开始时或当你受到伤害后，你可以观看牌堆顶三张牌，然后获得其中与其余牌花色均不同的一张牌。",

  ["#zhenxing-get"] = "镇行：你可以获得其中一张牌",

  ["$zhenxing1"] = "兵行万土，得御安危。",
  ["$zhenxing2"] = "边境镇威，万军难进。",
}

Fk:addPoxiMethod{
  name = "zhenxing",
  prompt = "#zhenxing-get",
  card_filter = function(to_select, selected, data)
    if #selected == 0 then
      return not table.find(data[1][2], function (id)
        return id ~= to_select and Fk:getCardById(id):compareSuitWith(Fk:getCardById(to_select))
      end)
    end
  end,
  feasible = function(selected)
    return #selected == 1
  end,
}

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = room:askToPoxi(player, {
      poxi_type = zhenxing.name,
      data = { { "Top", room:getNCards(3) } },
      cancelable = true,
    })
    if #result > 0 then
      room:obtainCard(player, result, false, fk.ReasonJustMove, player, zhenxing.name)
    end
  end,
}

zhenxing:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhenxing.name)
  end,
  on_use = spec.on_use,
})

zhenxing:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhenxing.name) and player.phase == Player.Finish
  end,
  on_use = spec.on_use,
})

return zhenxing
