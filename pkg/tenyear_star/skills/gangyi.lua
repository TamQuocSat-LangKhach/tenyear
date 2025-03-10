local gangyi = fk.CreateSkill {
  name = "gangyi"
}

Fk:loadTranslationTable{
  ['gangyi'] = '刚毅',
  [':gangyi'] = '锁定技，若你于回合内未造成过伤害，你于此回合内不能使用【桃】。当你因执行【桃】或【酒】的作用效果而回复体力时，若你处于濒死状态，你令回复值+1。',
  ['$gangyi1'] = '不见狼居胥，何妨马革裹尸。',
  ['$gangyi2'] = '既无功，不受禄。',
}

gangyi:addEffect(fk.PreHpRecover, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.dying and player:hasSkill(skill.name) and
      data.card and table.contains({"peach", "analeptic"}, data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    data.num = data.num + 1
  end,
})

gangyi:addEffect(fk.AskForPeaches, {
  global = false,
  can_refresh = function(self, event, target, player, data)
    if player.phase == Player.NotActive then return false end
    return player == target and player:hasSkill(skill.name) and player:getMark("gangyi-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, skill.name, "negative")
    player:broadcastSkillInvoke(skill.name)
  end,
})

gangyi:addEffect(fk.HpChanged, {
  global = false,
  can_refresh = function(self, event, target, player, data)
    return data.damageEvent and player == data.damageEvent.from and
      player:hasSkill(skill.name, true) and player:getMark("gangyi-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "gangyi-turn", 1)
  end,
})

gangyi:addEffect(fk.EventAcquireSkill, {
  global = false,
  can_refresh = function(self, event, target, player, data)
    if player == target and data == skill.name and player:getMark("gangyi-turn") == 0 then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if not turn_event then return false end
      return #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data[1].from == player
      end, nil, turn_event.id) > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "gangyi-turn", 1)
  end,
})

local gangyi_prohibit = fk.CreateSkill {
  name = "#gangyi_prohibit"
}

gangyi_prohibit:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    return card.name == "peach" and player.phase ~= Player.NotActive and
      player:hasSkill(gangyi.name) and player:getMark("gangyi-turn") == 0
  end,
})

return gangyi
