local jinjiu = fk.CreateSkill {
  name = "ty_ex__jinjiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_ex__jinjiu"] = "禁酒",
  [":ty_ex__jinjiu"] = "锁定技，你的【酒】视为点数为K的【杀】；你的回合内，其他角色不能使用【酒】。",

  ["$ty_ex__jinjiu1"] = "好酒之徒，难堪大任，不入我营！",
  ["$ty_ex__jinjiu2"] = "饮酒误事，必当严禁！",
}

jinjiu:addEffect("filter", {
  anim_type = "offensive",
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(jinjiu.name) and card.name == "analeptic" and
      (table.contains(player:getCardIds("h"), card.id) or isJudgeEvent)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, 13)
  end,
})

jinjiu:addEffect("prohibit", {
  prohibit_use = function (self, player, card)
    if Fk:currentRoom().current:hasSkill(jinjiu.name) then
      return player ~= Fk:currentRoom().current and card and card.name == "analeptic"
    end
  end,
})

return jinjiu
