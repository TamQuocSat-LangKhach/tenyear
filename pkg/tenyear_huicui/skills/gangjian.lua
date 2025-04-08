local gangjian = fk.CreateSkill {
  name = "gangjian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["gangjian"] = "刚简",
  [":gangjian"] = "锁定技，每个回合结束时，若你本回合未受到过伤害，你摸X张牌。（X为本回合展示或因拼点亮出的牌数，至多为5）。",

  ["$gangjian1"] = "道同则谋，道不同则不相为谋。",
  ["$gangjian2"] = "怎么，陈尚书要教我几句道德仁义？",
}

gangjian:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gangjian.name) and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.to == player
      end, Player.HistoryTurn) == 0 and
      (player:getMark("gangjian-turn") > 0 or
      #player.room.logic:getEventsOfScope(GameEvent.Pindian, 1, Util.TrueFunc, Player.HistoryTurn) > 0)
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getMark("gangjian-turn")
    player.room.logic:getEventsOfScope(GameEvent.Pindian, 1, function(e)
      local pindian = e.data
      if pindian.fromCard then
        n = n + 1
      end
      for _, result in pairs(pindian.results) do
        if result.toCard then
          n = n + 1
        end
      end
    end, Player.HistoryTurn)
    player:drawCards(math.min(n, 5), gangjian.name)
  end,
})

gangjian:addEffect(fk.CardShown, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(gangjian.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "gangjian-turn", #data.cardIds)
  end,
})

return gangjian
