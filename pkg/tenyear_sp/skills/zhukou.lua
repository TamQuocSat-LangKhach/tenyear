local zhukou = fk.CreateSkill {
  name = "zhukou",
}

Fk:loadTranslationTable{
  ["zhukou"] = "逐寇",
  [":zhukou"] = "当你于每回合的出牌阶段首次造成伤害后，你可以摸X张牌（X为本回合你已使用的牌数）。结束阶段，若你本回合未造成过伤害，"..
  "你可以对两名其他角色各造成1点伤害。",

  ["#zhukou-invoke"] = "逐寇：你可以摸%arg张牌",
  ["#zhukou-choose"] = "逐寇：你可以对两名其他角色各造成1点伤害",

  ["$zhukou1"] = "草莽贼寇，不过如此。",
  ["$zhukou2"] = "轻装上阵，利剑出鞘。",
}

zhukou:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhukou.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      local room = player.room
      if room.current and room.current.phase == Player.Play then
        local damage_events = room.logic:getActualDamageEvents(1, function (e)
          return e.data.from == player
        end, Player.HistoryPhase)
        if #damage_events == 1 and damage_events[1].data == data then
          local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function (e)
            return e.data.from == player
          end, Player.HistoryTurn)
          if n > 0 then
            event:setCostData(self, {choice = n})
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhukou.name,
      prompt = "#zhukou-invoke:::"..event:getCostData(self).choice,
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self).choice, zhukou.name)
  end,
})

zhukou:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhukou.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 1 and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 2,
      max_num = 2,
      prompt = "#zhukou-choose",
      skill_name = zhukou.name,
      cancelable = true,
    })
    if #tos == 2 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skill_name = zhukou.name,
        }
      end
    end
  end,
})

return zhukou
