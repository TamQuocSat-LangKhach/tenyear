local shizong = fk.CreateSkill {
  name = "shizong"
}

Fk:loadTranslationTable{
  ['shizong_active'] = '恃纵',
  ['shizong'] = '恃纵',
}

shizong:addEffect('active', {
  mute = true,
  card_num = function(self, player)
    return player:usedSkillTimes(shizong.name, Player.HistoryTurn)
  end,
  target_num = 1,
  card_filter = function(self, player, to_select, selected, targets)
    return #selected < player:usedSkillTimes(shizong.name, Player.HistoryTurn)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id
  end,
})

return shizong
