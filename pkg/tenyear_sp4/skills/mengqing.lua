local mengqing = fk.CreateSkill {
  name = "mengqing"
}

Fk:loadTranslationTable{
  ['mengqing'] = '氓情',
  [':mengqing'] = '觉醒技，准备阶段，若已受伤的角色数大于你的体力值，你加3点体力上限并回复3点体力，失去〖逐寇〗，获得〖玉殒〗。',
  ['$mengqing1'] = '女之耽兮，不可说也。',
  ['$mengqing2'] = '淇水汤汤，渐车帷裳。',
}

mengqing:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mengqing.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(mengqing.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 3)
    room:recover({
      who = player,
      num = 3,
      recoverBy = player,
      skillName = mengqing.name
    })
    room:handleAddLoseSkills(player, "-zhukou|yuyun", nil)
  end,
})

return mengqing
