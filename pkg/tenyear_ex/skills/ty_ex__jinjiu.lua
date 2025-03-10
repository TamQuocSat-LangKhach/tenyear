local ty_ex__jinjiu = fk.CreateSkill {
  name = "ty_ex__jinjiu"
}

Fk:loadTranslationTable{
  ['ty_ex__jinjiu'] = '禁酒',
  [':ty_ex__jinjiu'] = '锁定技，你的【酒】视为点数为K的【杀】；你的回合内，其他角色不能使用【酒】。',
  ['$ty_ex__jinjiu1'] = '好酒之徒，难堪大任，不入我营！',
  ['$ty_ex__jinjiu2'] = '饮酒误事，必当严禁！',
}

ty_ex__jinjiu:addEffect("filter", {
  card_filter = function(self, player, card, isJudgeEvent)
    return player:hasSkill(skill.name) and card.name == "analeptic" and
      (table.contains(player.player_cards[Player.Hand], card.id) or isJudgeEvent)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, 13)
  end,
})

return ty_ex__jinjiu
