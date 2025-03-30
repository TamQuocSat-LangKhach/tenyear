local kunli = fk.CreateSkill {
  name = "kunli",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["kunli"] = "困励",
  [":kunli"] = "觉醒技，当你进入濒死状态时，你将体力值回复至2点，加1点体力上限，并失去〖匮饬〗。",

  ["$kunli1"] = "回首万重山，难阻轻舟一叶。",
  ["$kunli2"] = "已过山穷水尽，前有柳暗花明。",
}

kunli:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kunli.name) and
      player:usedSkillTimes(kunli.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.hp < math.min(2, player.maxHp) then
      room:recover{
        who = player,
        num = math.min(2, player.maxHp) - player.hp,
        recoverBy = player,
        skill_name = kunli.name,
      }
    end
    if not player.dead then
      room:changeMaxHp(player, 1)
    end
    if not player.dead then
      room:handleAddLoseSkills(player, "-kuichi")
    end
  end,
})

return kunli
