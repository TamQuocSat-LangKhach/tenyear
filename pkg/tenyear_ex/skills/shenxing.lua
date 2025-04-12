local shenxing = fk.CreateSkill {
  name = "ty_ex__shenxing",
}

Fk:loadTranslationTable{
  ["ty_ex__shenxing"] = "慎行",
  [":ty_ex__shenxing"] = "出牌阶段，你可以弃置X张牌，然后摸一张牌（X为你此阶段发动本技能次数，至多为2）。",

  ["#ty_ex__shenxing-draw"] = "慎行：你可以摸一张牌",
  ["#ty_ex__shenxing"] = "慎行：你可以弃置%arg张牌，摸一张牌",

  ["$ty_ex__shenxing1"] = "谋而后动，行不容差。",
  ["$ty_ex__shenxing2"] = "谋略之道，需慎之又慎。",
}

shenxing:addEffect("active", {
  anim_type = "drawcard",
  card_num = function(self, player)
    return math.min(2, player:usedSkillTimes(shenxing.name, Player.HistoryPhase))
  end,
  target_num = 0,
  prompt = function(self, player)
    local n = player:usedSkillTimes(shenxing.name, Player.HistoryPhase)
    if n == 0 then
      return "#ty_ex__shenxing-draw"
    else
      return "#ty_ex__shenxing:::"..math.min(2, n)
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < math.min(2, player:usedSkillTimes(shenxing.name, Player.HistoryPhase)) and
      not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, shenxing.name, player, player)
    if not player.dead then
      player:drawCards(1, shenxing.name)
    end
  end,
})

return shenxing
