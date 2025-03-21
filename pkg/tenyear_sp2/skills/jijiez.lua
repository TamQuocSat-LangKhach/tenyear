local jijiez = fk.CreateSkill {
  name = "jijiez"
}

Fk:loadTranslationTable{
  ['jijiez'] = '己诫',
  [':jijiez'] = '锁定技，每回合各限一次，当其他角色于其回合外得到牌后/回复体力后，你摸等量的牌/回复等量的体力。',
  ['$jijiez1'] = '闻古贤女，未有不学前世成败者。',
  ['$jijiez2'] = '不知书，何由见之。',
}

jijiez:addEffect(fk.AfterCardsMove, {
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jijiez.name) then
      if player:getMark("jijiez_draw-turn") > 0 then return false end
      local ban_players = {player.id}
      if player.room.current.phase ~= Player.NotActive then
        table.insert(ban_players, player.room.current.id)
      end
      local x = 0
      for _, move in ipairs(target) do
        if move.to and not table.contains(ban_players, move.to) and move.toArea == Card.PlayerHand then
          x = x + #move.moveInfo
        end
      end
      if x > 0 then
        event:setCostData(skill, x)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(jijiez.name)
    room:notifySkillInvoked(player, jijiez.name, "drawcard")
    room:setPlayerMark(player, "jijiez_draw-turn", 1)
    player:drawCards(event:getCostData(skill), jijiez.name)
  end,
})

jijiez:addEffect(fk.HpRecover, {
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jijiez.name) then
      return player:getMark("jijiez_recover-turn") == 0 and player:isWounded() and
        target ~= player and target.phase == Player.NotActive
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(jijiez.name)
    room:notifySkillInvoked(player, jijiez.name, "support")
    room:setPlayerMark(player, "jijiez_recover-turn", 1)
    room:recover{
      who = player,
      num = target.num,
      recoverBy = player,
      skillName = jijiez.name,
    }
  end,
})

jijiez:addEffect('lose', {
  on_lose = function (skill, player)
    local room = player.room
    room:setPlayerMark(player, "jijiez_draw-turn", 0)
    room:setPlayerMark(player, "jijiez_recover-turn", 0)
  end,
})

return jijiez
