local skill = fk.CreateSkill {
  name = "#red_spear_skill",
  attached_equip = "red_spear",
}

Fk:loadTranslationTable{
  ["#red_spear_skill"] = "红缎枪",
}

skill:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash" and
      player:usedSkillTimes(skill.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = skill.name,
      pattern = ".",
    }
    room:judge(judge)
    if player.dead then return end
    if judge.card.color == Card.Red then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = skill.name,
        }
      end
    elseif judge.card.color == Card.Black then
      player:drawCards(2, skill.name)
    end
  end,
})

return skill
