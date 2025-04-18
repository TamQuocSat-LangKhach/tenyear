local jiezhong = fk.CreateSkill {
  name = "ty_ex__jiezhong",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ty_ex__jiezhong"] = "竭忠",
  [":ty_ex__jiezhong"] = "限定技，出牌阶段开始时，你可以将手牌摸至体力上限。",

  ["$ty_ex__jiezhong1"] = "犯我疆土者，竭忠尽节以灭之。",
  ["$ty_ex__jiezhong2"] = "竭力尽能以立功于国，忠心不二。",
}

jiezhong:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiezhong.name) and player.phase == Player.Play and
      player.maxHp > player:getHandcardNum() and
      player:usedSkillTimes(jiezhong.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), jiezhong.name)
  end,
})

return jiezhong
