local gangu = fk.CreateSkill {
  name = "gangu"
}

Fk:loadTranslationTable{
  ['gangu'] = '干蛊',
  [':gangu'] = '锁定技，每回合限一次，当一名角色失去体力后，你摸三张牌，失去1点体力。',
  ['$gangu1'] = '承志奉祠，达于行伍之事。',
  ['$gangu2'] = '干父之蛊，全辽裔未竟之业。',
}

gangu:addEffect(fk.HpLost, {
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(gangu.name) and player:usedSkillTimes(gangu.name) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, gangu.name)
    if not player.dead then
      player.room:loseHp(player, 1, {
        skill_name = gangu.name
      })
    end
  end,
})

return gangu
