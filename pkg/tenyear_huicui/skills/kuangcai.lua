local kuangcai = fk.CreateSkill {
  name = "kuangcai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["kuangcai"] = "狂才",
  [":kuangcai"] = "锁定技，你的回合内，你使用牌无距离和次数限制。<br>弃牌阶段开始时，若你本回合：没有使用过牌，你的手牌上限+1；"..
  "使用过牌且没有造成伤害，你手牌上限-1。<br>结束阶段，若你本回合造成过伤害，你摸等于伤害值数量的牌（最多摸五张）。",

  ["$kuangcai1"] = "耳所瞥闻，不忘于心。",
  ["$kuangcai2"] = "吾焉能从屠沽儿耶？",
}

kuangcai:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(kuangcai.name) then
      if player.phase == Player.Discard then
        local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          return e.data.from == player
        end, Player.HistoryTurn)
        if #use_events == 0 then
          event:setCostData(self, {choice = "noused"})
          return true
        elseif #player.room.logic:getActualDamageEvents(1, function(e)
          return e.data.from == player
        end) == 0 then
          event:setCostData(self, {choice = "used"})
          return true
        end
      elseif player.phase == Player.Finish then
        local n = 0
        player.room.logic:getActualDamageEvents(1, function(e)
          if e.data.from == player then
            n = n + e.data.damage
          end
        end)
        if n > 0 then
          event:setCostData(self, {choice = n})
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(kuangcai.name)
    local choice = event:getCostData(self).choice
    if player.phase == Player.Discard then
      if choice == "noused" then
        room:notifySkillInvoked(player, kuangcai.name, "support")
        room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
      else
        room:notifySkillInvoked(player, kuangcai.name, "negative")
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
      end
    elseif player.phase == Player.Finish then
      room:notifySkillInvoked(player, kuangcai.name, "drawcard")
      player:drawCards(math.min(choice, 5), kuangcai.name)
    end
  end,
})

kuangcai:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(kuangcai.name) and Fk:currentRoom().current == player
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(kuangcai.name) and Fk:currentRoom().current == player
  end,
})

return kuangcai
