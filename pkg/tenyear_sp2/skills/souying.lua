local souying = fk.CreateSkill {
  name = "souying"
}

Fk:loadTranslationTable{
  ['souying'] = '薮影',
  ['#souying1-invoke'] = '薮影：你可以弃置一张牌，获得此%arg',
  ['#souying2-invoke'] = '薮影：你可以弃置一张牌，令此%arg对你无效',
  [':souying'] = '每回合限一次，当你使用基本牌或普通锦囊牌指定其他角色为唯一目标后，若此牌不是本回合你对其使用的第一张牌，你可以弃置一张牌获得之；当其他角色使用基本牌或普通锦囊牌指定你为唯一目标后，若此牌不是本回合其对你使用的第一张牌，你可以弃置一张牌令此牌对你无效。',
  ['$souying1'] = '幽薮影单，只身勇斗！',
  ['$souying2'] = '真薮影移，险战不惧！',
}

souying:addEffect(fk.TargetSpecified, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(souying.name) and not player:isNude() and player:usedSkillTimes(souying.name, Player.HistoryTurn) == 0 and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and #AimGroup:getAllTargets(data.tos) == 1 then
      local room = player.room
      local events = {}
      if target == player then
        if data.to == player.id or room:getCardArea(data.card) ~= Card.Processing then return false end
        events = room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          local use = e.data[1]
          return use.from == player.id and table.contains(TargetGroup:getRealTargets(use.tos), data.to)
        end, Player.HistoryTurn)
      else
        if AimGroup:getAllTargets(data.tos)[1] ~= player.id then return false end
        events = room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          local use = e.data[1]
          return use.from == target.id and table.contains(TargetGroup:getRealTargets(use.tos), player.id)
        end, Player.HistoryTurn)
      end
      return #events > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if target == player then
      prompt = "#souying1-invoke:::"..data.card:toLogString()
    else
      prompt = "#souying2-invoke:::"..data.card:toLogString()
    end
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = souying.name,
      cancelable = true,
      pattern = ".",
      prompt = prompt,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self), souying.name, player, player)
    player:broadcastSkillInvoke(souying.name)
    if target == player then
      room:notifySkillInvoked(player, souying.name, "drawcard")
      if not player.dead and room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player, data.card, true, fk.ReasonJustMove)
      end
    else
      room:notifySkillInvoked(player, souying.name, "defensive")
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
  end,
})

return souying
