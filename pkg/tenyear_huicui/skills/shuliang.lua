local shuliang = fk.CreateSkill {
  name = "ty__shuliang",
}

Fk:loadTranslationTable{
  ["ty__shuliang"] = "输粮",
  [":ty__shuliang"] = "每个回合结束时，你可以交给任意名没有手牌的其他角色各一张牌。若此牌可指定该角色自己为目标，则其可以使用此牌。",

  ["#ty__shuliang-give"] = "输粮：你可以交给任意名没有手牌的角色各一张牌，其可以对自己使用之",
  ["#ty__shuliang-use"] = "输粮：是否对自己使用%arg？",

  ["$ty__shuliang1"] = "北伐鏖战正酣，此正需粮之时。",
  ["$ty__shuliang2"] = "粮草先于兵马而动，此军心之本。",
}

shuliang:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shuliang.name) and
      not player:isNude() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:isKongcheng()
    end)
    local result = room:askToYiji(player, {
      cards = player:getCardIds("he"),
      targets = targets,
      skill_name = shuliang.name,
      min_num = 0,
      max_num = 9,
      prompt = "#ty__shuliang-give",
      skip = true,
      single_max = 1,
    })
    for _, ids in pairs(result) do
      if #ids > 0 then
        event:setCostData(self, {extra_data = result})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = event:getCostData(self).extra_data
    room:doYiji(result, player, shuliang.name)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and result[p.id] and #result[p.id] > 0 and table.contains(p:getCardIds("h"), result[p.id][1]) then
        local card = Fk:getCardById(result[p.id][1])
        if p:canUseTo(card, p, { bypass_times = true }) and
          room:askToSkillInvoke(p, {
            skill_name = shuliang.name,
            prompt = "#ty__shuliang-use:::"..card:toLogString(),
          }) then
          local use = {
            from = p,
            tos = {p},
            card = card,
            extra_use = true,
          }
          room:useCard(use)
        end
      end
    end
  end,
})

return shuliang
