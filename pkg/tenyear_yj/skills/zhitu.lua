local zhitu = fk.CreateSkill {
  name = "zhitu",
}

Fk:loadTranslationTable{
  ["zhitu"] = "制图",
  [":zhitu"] = "你使用基本牌和单目标普通锦囊牌可以指定任意名你与其距离相等的角色为目标。",

  ["#zhitu-choose"] = "制图：你可以为%arg指定任意名距离为%arg2的角色为额外目标",

  ["$zhitu1"] = "辨广轮之度，正彼此之体，远近无所隐其形。",
  ["$zhitu2"] = "地有六合，图有六体，可校其经纬。",
}

zhitu:addEffect(fk.AfterCardTargetDeclared, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhitu.name) and
      (data.card.type == Card.TypeBasic or (data.card:isCommonTrick() and not data.card.multiple_targets)) then
      return table.every(data.tos, function(p)
        return player:distanceTo(p) == player:distanceTo(data.tos[1])
      end) and
      table.find(data:getExtraTargets({bypass_distances = true}), function(p)
        return player:distanceTo(p) == player:distanceTo(data.tos[1])
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({bypass_distances = true}), function(p)
      return player:distanceTo(p) == player:distanceTo(data.tos[1])
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 10,
      prompt = "#zhitu-choose:::"..data.card:toLogString()..":"..player:distanceTo(data.tos[1]),
      skill_name = zhitu.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
  end,
})

return zhitu
