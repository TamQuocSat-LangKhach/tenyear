local souying = fk.CreateSkill {
  name = "souying",
}

Fk:loadTranslationTable{
  ["souying"] = "薮影",
  [":souying"] = "每回合限一次，当你使用基本牌或普通锦囊牌指定其他角色为唯一目标后，若此牌不是本回合你对其使用的第一张牌，"..
  "你可以弃置一张牌获得之；当其他角色使用基本牌或普通锦囊牌指定你为唯一目标后，若此牌不是本回合其对你使用的第一张牌，"..
  "你可以弃置一张牌令此牌对你无效。",

  ["#souying1-invoke"] = "薮影：你可以弃置一张牌，获得此%arg",
  ["#souying2-invoke"] = "薮影：你可以弃置一张牌，令此%arg对你无效",

  ["$souying1"] = "幽薮影单，只身勇斗！",
  ["$souying2"] = "真薮影移，险战不惧！",
}

souying:addEffect(fk.TargetSpecified, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(souying.name) and not player:isNude() and
      player:usedSkillTimes(souying.name, Player.HistoryTurn) == 0 and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and data:isOnlyTarget(data.to) then
      local use_events = {}
      if target == player then
        if data.to == player or player.room:getCardArea(data.card) ~= Card.Processing then return end
        use_events = player.room.logic:getEventsByRule(GameEvent.UseCard, 2, function(e)
          local use = e.data
          return use.from == player and table.contains(use.tos, data.to)
        end, nil, Player.HistoryTurn)
      elseif data.to == player then
        use_events = player.room.logic:getEventsByRule(GameEvent.UseCard, 2, function(e)
          local use = e.data
          return use.from == target and table.contains(use.tos, player)
        end, nil, Player.HistoryTurn)
      end
      return #use_events > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt
    if target == player then
      prompt = "#souying1-invoke:::"..data.card:toLogString()
    else
      prompt = "#souying2-invoke:::"..data.card:toLogString()
    end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = souying.name,
      cancelable = true,
      prompt = prompt,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, souying.name, player, player)
    player:broadcastSkillInvoke(souying.name)
    if target == player then
      room:notifySkillInvoked(player, souying.name, "drawcard")
      if not player.dead and room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, souying.name)
      end
    else
      room:notifySkillInvoked(player, souying.name, "defensive")
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      table.insertIfNeed(data.use.nullifiedTargets, player)
    end
  end,
})

return souying
