local shangjue = fk.CreateSkill {
  name = "shangjue"
}

Fk:loadTranslationTable{
  ['shangjue'] = '殇决',
  ['kunli'] = '困励',
  [':shangjue'] = '觉醒技，当你进入濒死状态时，你将体力值回复至1点，加1点体力上限，并获得〖困励〗，然后将〖铿锵〗改为每回合各限一次。',
  ['$shangjue1'] = '伯约，奈何桥畔，再等我片刻。',
  ['$shangjue2'] = '与君同生共死，岂可空待黄泉！'
}

shangjue:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(shangjue.name) and
      player:usedSkillTimes(shangjue.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player)
    return player.dying
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:recover({
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = shangjue.name,
    })
    if not player.dead then
      room:changeMaxHp(player, 1)
    end
    if not player.dead then
      room:handleAddLoseSkills(player, "kunli", nil, true, false)
    end
  end,
})

return shangjue
