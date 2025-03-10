local songsang = fk.CreateSkill {
  name = "songsang"
}

Fk:loadTranslationTable{
  ['songsang'] = '送丧',
  ['zhanji'] = '展骥',
  [':songsang'] = '限定技，当其他角色死亡时，若你已受伤，你可回复1点体力；若你未受伤，你可加1点体力上限。然后你获得〖展骥〗。',
  ['$songsang1'] = '送丧至东吴，使命已完。',
  ['$songsang2'] = '送丧虽至，吾与孝则得相交。',
}

songsang:addEffect(fk.Death, {
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name) and player:usedSkillTimes(songsang.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skill_name = songsang.name,
      })
    else
      room:changeMaxHp(player, 1)
    end
    room:handleAddLoseSkills(player, "zhanji", nil, true, false)
  end,
})

return songsang
