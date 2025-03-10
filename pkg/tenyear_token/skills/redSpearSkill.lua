local redSpearSkill = fk.CreateSkill {
  name = "#red_spear_skill"
}

Fk:loadTranslationTable{
  ['#red_spear_skill'] = '红缎枪',
  ['red_spear'] = '红缎枪',
}

redSpearSkill:addEffect(fk.Damage, {
  attached_equip = "red_spear",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(redSpearSkill) and data.card and data.card.trueName == "slash" and
      player:usedSkillTimes(redSpearSkill.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = redSpearSkill.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = redSpearSkill.name
        })
      end
    elseif judge.card.color == Card.Black then
      if not player.dead then
        player:drawCards(2, redSpearSkill.name)
      end
    end
  end,
})

return redSpearSkill
