local houde = fk.CreateSkill {
  name = "houde",
}

Fk:loadTranslationTable{
  ["houde"] = "厚德",
  [":houde"] = "当你于其他角色的出牌阶段内：首次成为红色【杀】的目标后，你可以弃置一张牌，令此【杀】对你无效；首次成为黑色普通锦囊牌的目标后，"..
  "你可以弃置其一张牌，令此锦囊牌对你无效。",

  ["#houde-slash-invoke"] = "厚德：你可以弃置一张牌，令此%arg对你无效",
  ["#houde-trick-invoke"] = "厚德：你可以弃置 %dest 一张牌，令此%arg对你无效",

  ["$houde1"] = "君子有德，可以载天下之重。",
  ["$houde2"] = "南山有松，任尔风雨雷霆。",
}

houde:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(houde.name) then
      local room = player.room
      if room.current == player or room.current.phase ~= Player.Play then return false end
      if data.card.trueName == "slash" then
        if data.card.color ~= Card.Red or player:isNude() then return false end
        local mark = player:getMark("houde_slash-phase")
        local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if use_event == nil then return false end
        if mark == 0 then
          room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
            local use = e.data
            if use.card.trueName == "slash" and use.card.color == Card.Red and
              table.contains(use.tos, player) then
              mark = e.id
              room:setPlayerMark(player, "houde_slash-phase", mark)
              return true
            end
          end, Player.HistoryPhase)
        end
        return mark == use_event.id
      elseif data.card:isCommonTrick() then
        if data.card.color ~= Card.Black or room.current.dead or room.current:isNude() then return false end
        local mark = player:getMark("houde_trick-phase")
        local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if use_event == nil then return false end
        if mark == 0 then
          room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
            local use = e.data
            if use.card:isCommonTrick() and use.card.color == Card.Black and
              table.contains(use.tos, player) then
              mark = e.id
              room:setPlayerMark(player, "houde_trick-phase", mark)
              return true
            end
          end, Player.HistoryPhase)
        end
        return mark == use_event.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if data.card.trueName == "slash" then
      local card = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = houde.name,
        cancelable = true,
        prompt = "#houde-slash-invoke:::"..data.card:toLogString(),
        skip = true,
      })
      if #card > 0 then
        event:setCostData(self, {cards = card})
        return true
      end
    else
      if room:askToSkillInvoke(player, {
        skill_name = houde.name,
        prompt = "#houde-trick-invoke::"..room.current.id..":"..data.card:toLogString()
      }) then
        event:setCostData(self, {target = {room.current}})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.trueName == "slash" then
      room:throwCard(event:getCostData(self).cards, houde.name, player, player)
    else
      local id = room:askToChooseCard(player, {
        target = room.current,
        flag = "he",
        skill_name = houde.name,
      })
      room:throwCard(id, houde.name, room.current, player)
    end
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)
  end,
})

return houde
