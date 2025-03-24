local gangyi = fk.CreateSkill {
  name = "gangyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["gangyi"] = "刚毅",
  [":gangyi"] = "锁定技，若你于回合内未造成过伤害，你于此回合内不能使用【桃】。当你于濒死状态因【桃】或【酒】回复体力时，回复值+1。",

  ["$gangyi1"] = "不见狼居胥，何妨马革裹尸。",
  ["$gangyi2"] = "既无功，不受禄。",
}

gangyi:addEffect(fk.PreHpRecover, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.dying and player:hasSkill(gangyi.name) and
      data.card and table.contains({"peach", "analeptic"}, data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    data:changeRecover(1)
  end,
})

gangyi:addEffect(fk.AskForPeaches, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(gangyi.name) and
      player:getMark("gangyi-turn") == 0 and player.room.current == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, gangyi.name, "negative")
    player:broadcastSkillInvoke(gangyi.name)
  end,
})

gangyi:addEffect(fk.HpChanged, {
  can_refresh = function(self, event, target, player, data)
    return data.damageEvent and player == data.damageEvent.from and
      player:hasSkill(gangyi.name, true) and player:getMark("gangyi-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "gangyi-turn", 1)
  end,
})

gangyi:addAcquireEffect(function (self, player, is_start)
  if not is_start and player.room.current == player then
    if #player.room.logic:getActualDamageEvents(1, function(e)
      return e.data.from == player
    end, Player.HistoryTurn) > 0 then
      player.room:setPlayerMark(player, "gangyi-turn", 1)
    end
  end
end)

gangyi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card.name == "peach" and Fk:currentRoom().current == player and
      player:hasSkill(gangyi.name) and player:getMark("gangyi-turn") == 0
  end,
})

return gangyi
