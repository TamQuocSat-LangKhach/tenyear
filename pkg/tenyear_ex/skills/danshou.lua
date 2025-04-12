local danshou = fk.CreateSkill {
  name = "ty_ex__danshou",
}

Fk:loadTranslationTable{
  ["ty_ex__danshou"] = "胆守",
  [":ty_ex__danshou"] = "每回合限一次，当你成为基本牌或锦囊牌的目标后，你可以摸X张牌（X为你本回合成为基本牌或锦囊牌目标的次数）；"..
  "一名角色的结束阶段，若你本回合没有以此法摸牌，你可以弃置其手牌数的牌，对其造成1点伤害。",

  ["#ty_ex__danshou-draw"] = "胆守：你可以摸%arg张牌",
  ["#ty_ex__danshou-invoke"] = "胆守：你可以对 %dest 造成1点伤害",
  ["#ty_ex__danshou-discard"] = "胆守：你可以弃置%arg张牌，对 %dest 造成1点伤害",
  ["@ty_ex__danshou-turn"] = "胆守",

  ["$ty_ex__danshou1"] = "胆识过人而劲勇，则见敌无所畏惧",
  ["$ty_ex__danshou2"] = "胆守有余，可堪大任！"
}

danshou:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(danshou.name) and data.card.type ~= Card.TypeEquip and
      player:usedSkillTimes(danshou.name, Player.HistoryTurn) == 0 and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.card.type ~= Card.TypeEquip and table.contains(use.tos, player)
      end, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data
      return use.card.type ~= Card.TypeEquip and table.contains(use.tos, player)
    end, Player.HistoryTurn)
    if room:askToSkillInvoke(player, {
      skill_name = danshou.name,
      prompt = "#ty_ex__danshou-draw:::"..n,
    }) then
      event:setCostData(self, {choice = n})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty_ex__danshou-turn", 0)
    player:drawCards(event:getCostData(self).choice, danshou.name)
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.type ~= Card.TypeEquip and player:hasSkill(danshou.name, true) and
      player:usedSkillTimes(danshou.name, Player.HistoryTurn) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data
      return use.card.type ~= Card.TypeEquip and table.contains(use.tos, player)
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "@ty_ex__danshou-turn", n)
  end,
})

danshou:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(danshou.name) and target.phase == Player.Finish and
      player:usedSkillTimes(danshou.name, Player.HistoryTurn) == 0 and not target.dead and
      #player:getCardIds("he") >= target:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = target:getHandcardNum()
    if n == 0 then
      if room:askToSkillInvoke(player, {
        skill_name = danshou.name,
        prompt = "#ty_ex__danshou-invoke::"..target.id,
      }) then
        event:setCostData(self, {tos = {target}})
        return true
      end
    else
      local cards = room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = danshou.name,
        cancelable = true,
        prompt = "#ty_ex__danshou-discard::"..target.id..":" .. n,
        skip = true
      })
      if #cards == n then
        event:setCostData(self, {tos = {target}, cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    if cards then
      room:throwCard(cards, danshou.name, player, player)
    end
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = danshou.name,
      }
    end
  end,
})

danshou:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@ty_ex__danshou-turn", 0)
end)

return danshou
