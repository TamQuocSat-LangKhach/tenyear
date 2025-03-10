local zhitu = fk.CreateSkill {
  name = "zhitu"
}

Fk:loadTranslationTable{
  ['zhitu'] = '制图',
  ['#zhitu-choose'] = '制图：你可以为%arg指定任意名距离为%arg2的角色为额外目标',
  [':zhitu'] = '你使用基本牌和单目标普通锦囊牌可以指定任意名你与其距离相等的角色为目标。',
  ['$zhitu1'] = '辨广轮之度，正彼此之体，远近无所隐其形。',
  ['$zhitu2'] = '地有六合，图有六体，可校其经纬。',
}

zhitu:addEffect(fk.AfterCardTargetDeclared, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhitu.name) and
      (data.card.type == Card.TypeBasic or (data.card:isCommonTrick() and not data.card.multiple_targets)) then
      local to = player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
      return table.every(TargetGroup:getRealTargets(data.tos), function(id)
        return player:distanceTo(player.room:getPlayerById(id)) == player:distanceTo(to)
      end) and
        table.find(player.room:getUseExtraTargets(data), function(id)
          return player:distanceTo(to) == player:distanceTo(player.room:getPlayerById(id))
        end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    local targets = table.filter(room:getUseExtraTargets(data), function(id)
      return player:distanceTo(to) == player:distanceTo(room:getPlayerById(id))
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 10,
      prompt = "#zhitu-choose:::" .. data.card:toLogString() .. ":" .. player:distanceTo(to),
      skill_name = zhitu.name,
      cancelable = true
    })
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      event:setCostData(skill, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost_data = event:getCostData(skill)
    for _, id in ipairs(cost_data.tos) do
      table.insert(data.tos, {id})
    end
  end,
})

return zhitu
