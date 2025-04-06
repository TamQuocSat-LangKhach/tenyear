local manyi = fk.CreateSkill {
  name = "manyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["manyi"] = "蛮裔",
  [":manyi"] = "锁定技，【南蛮入侵】对你无效。",

  ["$manyi1"] = "南蛮女子，该当英勇善战！",
  ["$manyi2"] = "蛮族的力量，你可不要小瞧！",
}

manyi:addEffect(fk.PreCardEffect, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(manyi.name) and data.card.trueName == "savage_assault" and data.to == player
  end,
  on_use = function (self, event, target, player, data)
    data.nullified = true
  end,
})

return manyi
