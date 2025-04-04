local kuangcai = fk.CreateSkill {
  name = "kuangcai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['kuangcai'] = '狂才',
  [':kuangcai'] = '①锁定技，你的回合内，你使用牌无距离和次数限制。<br>②弃牌阶段开始时，若你本回合：没有使用过牌，你的手牌上限+1；使用过牌且没有造成伤害，你手牌上限-1。<br>③结束阶段，若你本回合造成过伤害，你摸等于伤害值数量的牌（最多摸五张）。',
  ['$kuangcai1'] = '耳所瞥闻，不忘于心。',
  ['$kuangcai2'] = '吾焉能从屠沽儿耶？',
}

-- Trigger Skill Effect
kuangcai:addEffect(fk.EventPhaseStart, {
  mute = true,
  
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(kuangcai.name) then
      if player.phase == Player.Discard then
        local used = #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data[1]
          return use.from == player.id
        end, Player.HistoryTurn) > 0
        if not used then
          event:setCostData(self, "noused")
          return true
        elseif #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == player end) == 0 then
          event:setCostData(self, "used")
          return true
        end
      elseif player.phase == Player.Finish then
        local n = 0
        player.room.logic:getActualDamageEvents(1, function(e)
          if e.data[1].from == player then
            n = n + e.data[1].damage
          end
        end)
        if n > 0 then
          event:setCostData(self, n)
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(kuangcai.name)
    if player.phase == Player.Discard then
      local a = event:getCostData(self)
      if a == "noused" then
        room:notifySkillInvoked(player, kuangcai.name, "support")
        room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
      else
        room:notifySkillInvoked(player, kuangcai.name, "negative")
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
      end
      room:broadcastProperty(player, "MaxCards")
    elseif player.phase == Player.Finish then
      local a = event:getCostData(self)
      room:notifySkillInvoked(player, kuangcai.name, "drawcard")
      player:drawCards(math.min(a, 5))
    end
  end,
})

-- TargetMod Skill Effect
kuangcai:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(kuangcai.name) and player.phase ~= Player.NotActive
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(kuangcai.name) and player.phase ~= Player.NotActive
  end,
})

return kuangcai
