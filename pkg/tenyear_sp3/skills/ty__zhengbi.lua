local ty__zhengbi = fk.CreateSkill {
  name = "ty__zhengbi"
}

Fk:loadTranslationTable{
  ['ty__zhengbi'] = '征辟',
  ['#ty__zhengbi-choose'] = '征辟：选择一名角色<br>点“确定”，若其此阶段获得手牌，此阶段结束时你获得其牌；<br>选一张基本牌点“确定”，将此牌交给其，然后其交给你一张非基本牌或两张基本牌。',
  ['#ty__zhengbi_delay'] = '征辟',
  [':ty__zhengbi'] = '出牌阶段开始时，你可以选择一名其他角色并选择一项：1.此阶段结束时，若其此阶段获得过手牌，你获得其一张手牌和装备区内一张牌；2.交给其一张基本牌，然后其交给你一张非基本牌或两张基本牌。',
  ['$ty__zhengbi1'] = '跅弛之士，在御之而已。',
  ['$ty__zhengbi2'] = '内不避亲，外不避仇。',
}

-- 主技能
ty__zhengbi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__zhengbi.name) and player.phase == Player.Play and #player.room.alive_players > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_card_num = 0,
      max_card_num = 1,
      min_target_num = 1,
      max_target_num = 1,
      pattern = ".|.|.|.|.|basic",
      skill_name = ty__zhengbi.name
    })
    if success and dat then
      if #dat.cards > 0 then
        event:setCostData(self, {tos = dat.targets, cards = dat.cards})
      else
        event:setCostData(self, {tos = dat.targets})
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    if event:getCostData(self).cards then
      room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, ty__zhengbi.name, nil, true, player.id)
      if player.dead or to.dead or to:isNude() then return end
      local cards = to:getCardIds("he")
      if #cards > 1 then
        local choices = {}
        local num = #table.filter(to:getCardIds(Player.Hand), function(id)
          return Fk:getCardById(id).type == Card.TypeBasic end)
        if num > 1 then
          table.insert(choices, "zhengbi__basic-back:"..player.id)
        end
        if #to:getCardIds("he") - num > 0 then
          table.insert(choices, "zhengbi__nobasic-back:"..player.id)
        end
        if #choices == 0 then return end
        local choice = room:askToChoice(to, {
          choices = choices,
          skill_name = ty__zhengbi.name
        })
        if choice:startsWith("zhengbi__basic-back") then
          cards = room:askToCards(to, {
            min_num = 2,
            max_num = 2,
            include_equip = false,
            pattern = ".|.|.|.|.|basic",
            prompt = "#ld__zhengbi-give1:"..player.id,
            skill_name = ty__zhengbi.name
          })
        else
          cards = room:askToCards(to, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            pattern = ".|.|.|.|.|^basic",
            prompt = "#ld__zhengbi-give2:"..player.id,
            skill_name = ty__zhengbi.name
          })
        end
      end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, ty__zhengbi.name, nil, true, to.id)
    else
      room:setPlayerMark(player, "ty__zhengbi-phase", to.id)
    end
  end,
})

-- 延迟技能
ty__zhengbi:addEffect(fk.EventPhaseEnd, {
  name = "#ty__zhengbi_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play and player:getMark("ty__zhengbi-phase") ~= 0 then
      local room = player.room
      local p = room:getPlayerById(player:getMark("ty__zhengbi-phase"))
      if p.dead or p:isNude() then return end
      return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          return move.to == p.id and move.toArea == Card.PlayerHand
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ty__zhengbi")
    room:notifySkillInvoked(player, "ty__zhengbi", "control")
    local to = room:getPlayerById(player:getMark("ty__zhengbi-phase"))
    room:doIndicate(player.id, {to.id})
    local cards = room:askToChooseCards(player, {
      target = to,
      min = 1,
      max = 1,
      flag = "he",
      skill_name = ty__zhengbi.name
    })
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, ty__zhengbi.name, nil, true, player.id)
  end,
})

return ty__zhengbi
