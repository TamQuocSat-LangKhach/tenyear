local ruxian = fk.CreateSkill {
  name = "ruxian",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ruxian"] = "儒贤",
  [":ruxian"] = "限定技，出牌阶段，你可以将〖彰才〗改为所有点数均可触发摸牌直到你的下回合开始。",

  ["#ruxian"] = "儒贤：令你发动“彰才”没有点数限制直到下个回合开始！",
  ["@@ruxian"] = "儒贤",

  ["$ruxian1"] = "儒道尚仁而有礼，贤者知命而独悟。",
  ["$ruxian2"] = "儒门有言，仁为己任，此生不负孔孟之礼。",
}

ruxian:addEffect("active", {
  name = "ruxian",
  prompt = "#ruxian",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(ruxian.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    room:setPlayerMark(effect.from, "@@ruxian", 1)
  end,
})

ruxian:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@ruxian") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ruxian", 0)
  end,
})

return ruxian
