local houde = fk.CreateSkill {
  name = "houde"
}

Fk:loadTranslationTable{
  ['houde'] = '厚德',
  ['#houde-slash-invoke'] = '是否发动 厚德，弃置一张牌，令%dest使用的%arg对你无效',
  ['#houde-trick-invoke'] = '是否发动 厚德，弃置%dest的一张牌，令%dest使用的%arg对你无效',
  [':houde'] = '当你于其他角色的出牌阶段内第一次成为红色【杀】/黑色普通锦囊牌的目标后，你可以弃置一张牌/弃置其一张牌，此【杀】/锦囊牌对你无效。',
  ['$houde1'] = '君子有德，可以载天下之重。',
  ['$houde2'] = '南山有松，任尔风雨雷霆。',
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
            local use = e.data[1]
            if use.card.trueName == "slash" and use.card.color == Card.Red and
              table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
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
            local use = e.data[1]
            if use.card:isCommonTrick() and use.card.color == Card.Black and
              table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
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
    if data.card.trueName == "slash" then
      local card = player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = houde.name,
        cancelable = true,
        pattern = ".",
        prompt = "#houde-slash-invoke::" .. data.from .. ":" .. data.card:toLogString(),
        skip = true
      })
      if #card > 0 then
        event:setCostData(skill, card)
        return true
      end
    else
      local room = player.room
      if room:askToSkillInvoke(player, {
        skill_name = houde.name,
        prompt = "#houde-trick-invoke:" .. room.current.id .. ":" .. data.from .. ":" .. data.card:toLogString()
      }) then
        room:doIndicate(player.id, {room.current.id})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if data.card.trueName == "slash" then
      local cost_data = event:getCostData(skill)
      player.room:throwCard(cost_data, houde.name, player, player)
    else
      local room = player.room
      local id = room:askToChooseCard(player, {
        target = room.current,
        flag = "he",
        skill_name = houde.name
      })
      room:throwCard({id}, houde.name, room.current, player)
    end
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
})

return houde
