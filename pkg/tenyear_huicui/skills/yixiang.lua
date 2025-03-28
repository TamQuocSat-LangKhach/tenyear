local yixiang = fk.CreateSkill {
  name = "ty__yixiang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__yixiang"] = "义襄",
  [":ty__yixiang"] = "锁定技，其他角色的出牌阶段内，其使用的第一张牌对你造成的伤害-1；其使用的第二张牌若为黑色，则对你无效。",

  ["$ty__yixiang1"] = "阿瞒！你可攻的下这徐州城！",
  ["$ty__yixiang2"] = "得道多助，失道寡助！",
}

yixiang:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(yixiang.name) and data.card then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event == nil then return end
      local from = use_event.data.from
      if from == player or from.phase ~= Player.Play then return end
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == from
      end, Player.HistoryPhase)
      return #use_events == 1 and use_events[1] == use_event
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
  end,
})

yixiang:addEffect(fk.PreCardEffect, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if data.to == player and player:hasSkill(yixiang.name) and
      data.card.color == Card.Black and data.from.phase == Player.Play then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event == nil then return end
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function (e)
        return e.data.from == data.from
      end, Player.HistoryPhase)
      return #use_events == 2 and use_events[2] == use_event
    end
  end,
  on_use = function(self, event, target, player, data)
    data.nullified = true
  end,
})

return yixiang
