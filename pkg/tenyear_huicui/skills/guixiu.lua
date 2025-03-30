local guixiu = fk.CreateSkill {
  name = "ty__guixiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__guixiu"] = "闺秀",
  [":ty__guixiu"] = "锁定技，你的第一个回合开始时，你摸两张牌；当你发动〖存嗣〗后，你回复1点体力。",

  ["$ty__guixiu1"] = "闺楼独看花月，倚窗顾影自怜。",
  ["$ty__guixiu2"] = "闺中女子，亦可秀气英拔。",
}

guixiu:addEffect(fk.AfterSkillEffect, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guixiu.name) and
      data.skill.name == "ty__cunsi" and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = guixiu.name,
    }
  end,
})

guixiu:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guixiu.name) and
      player:usedEffectTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, guixiu.name)
  end,
})

return guixiu
