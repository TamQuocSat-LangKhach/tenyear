local jijie = fk.CreateSkill {
  name = "jijiez",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jijiez"] = "己诫",
  [":jijiez"] = "锁定技，每回合各限一次，当其他角色于其回合外得到牌后/回复体力后，你摸等量的牌/回复等量的体力。",

  ["$jijiez1"] = "闻古贤女，未有不学前世成败者。",
  ["$jijiez2"] = "不知书，何由见之。",
}

jijie:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jijie.name) and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      local ban_players = {player}
      if player.room.current.phase ~= Player.NotActive then
        table.insert(ban_players, player.room.current)
      end
      local x = 0
      for _, move in ipairs(data) do
        if move.to and not table.contains(ban_players, move.to) and move.toArea == Card.PlayerHand then
          x = x + #move.moveInfo
        end
      end
      if x > 0 then
        event:setCostData(self, {choice = x})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self).choice, jijie.name)
  end,
})

jijie:addEffect(fk.HpRecover, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(jijie.name) and player:isWounded() and
      player.room.current ~= target and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = data.num,
      recoverBy = player,
      skillName = jijie.name,
    }
  end,
})

return jijie
