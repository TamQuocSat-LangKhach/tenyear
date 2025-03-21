local ty_ex__danshou = fk.CreateSkill {
  name = "ty_ex__danshou"
}

Fk:loadTranslationTable{
  ['ty_ex__danshou'] = '胆守',
  ['#ty_ex__danshou-draw'] = '胆守：你可以摸%arg张牌',
  ['#ty_ex__danshou-trigger'] = '胆守：你可以对 %dest 造成1点伤害',
  ['#ty_ex__danshou-damage'] = '胆守：你可以弃置%arg张牌，对 %dest 造成1点伤害',
  ['@ty_ex__danshou-turn'] = '胆守',
  [':ty_ex__danshou'] = '每回合限一次，当你成为基本牌或锦囊牌的目标后，你可以摸X张牌（X为你本回合成为基本牌或锦囊牌的目标次数）；一名角色的结束阶段，若你本回合没有以此法摸牌，你可以弃置其手牌数的牌，对其造成1点伤害。',
  ['$ty_ex__danshou1'] = '胆识过人而劲勇，则见敌无所畏惧',
  ['$ty_ex__danshou2'] = '胆守有余，可堪大任！'
}

ty_ex__danshou:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) and player:usedSkillTimes(ty_ex__danshou.name, Player.HistoryTurn) == 0 then
      if target == player and data.card.type ~= Card.TypeEquip then
        local n = 0
        local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
          local use = e.data[1]
          if use.card.type ~= Card.TypeEquip and table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
            n = n + 1
          end
        end, Player.HistoryTurn)
        return n > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirmed then
      local n = 0
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        if use.card.type ~= Card.TypeEquip and table.contains(TargetGroup:getRealTargets(use.tos), player.id) then
          n = n + 1
        end
      end, Player.HistoryTurn)
      if room:askToSkillInvoke(player, {
        skill_name = ty_ex__danshou.name,
        prompt = "#ty_ex__danshou-draw:::" .. n
      }) then
        event:setCostData(skill, n)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty_ex__danshou.name)
    if event == fk.TargetConfirmed then
      room:notifySkillInvoked(player, ty_ex__danshou.name, "drawcard")
      room:setPlayerMark(player, "@ty_ex__danshou-turn", 0)
      local n = event:getCostData(skill)
      player:drawCards(n, ty_ex__danshou.name)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.type ~= Card.TypeEquip
      and player:hasSkill(ty_ex__danshou.name, true) and player:usedSkillTimes("ty_ex__danshou", Player.HistoryTurn) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      return use.card.type ~= Card.TypeEquip and table.contains(TargetGroup:getRealTargets(use.tos), player.id)
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "@ty_ex__danshou-turn", #events)
  end,
})

ty_ex__danshou:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty_ex__danshou.name) and player:usedSkillTimes(ty_ex__danshou.name, Player.HistoryTurn) == 0 then
      return target.phase == Player.Finish and #player:getCardIds("he") >= target:getHandcardNum()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = target:getHandcardNum()
    local cards = {}
    local yes = false
    if n == 0 then
      if room:askToSkillInvoke(player, {
        skill_name = ty_ex__danshou.name,
        prompt = "#ty_ex__danshou-trigger::" .. target.id
      }) then
        yes = true
      end
    else
      cards = room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = ty_ex__danshou.name,
        cancelable = true,
        prompt = "#ty_ex__danshou-damage::" .. target.id .. ":" .. n,
        skip = true
      })
      if #cards == n then
        yes = true
      end
    end
    if yes then
      event:setCostData(skill, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty_ex__danshou.name)
    room:notifySkillInvoked(player, ty_ex__danshou.name, "offensive")
    room:throwCard(event:getCostData(skill), ty_ex__danshou.name, player, player)
    if not target.dead then
      room:doIndicate(player.id, {target.id})
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = ty_ex__danshou.name,
      }
    end
  end,
})

return ty_ex__danshou
