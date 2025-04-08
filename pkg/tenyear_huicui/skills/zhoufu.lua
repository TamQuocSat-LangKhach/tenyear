local zhoufu = fk.CreateSkill {
  name = "ty__zhoufu",
}

Fk:loadTranslationTable{
  ["ty__zhoufu"] = "咒缚",
  [":ty__zhoufu"] = "出牌阶段限一次，你可以将一张手牌置于一名没有“咒”的其他角色的武将牌旁，称为“咒”（当有“咒”的角色判定时，将“咒”作为判定牌）。",

  ["#ty__zhoufu"] = "咒缚：将一张手牌置为一名角色的“咒”，其判定时改为将“咒”作为判定牌",

  ["$ty__zhoufu1"] = "这束缚，可不是你能挣脱的！",
  ["$ty__zhoufu2"] = "咒术显灵，助我改运！"
}

zhoufu:addEffect("active", {
  anim_type = "control",
  prompt = "#ty__zhoufu",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhoufu.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select ~= player and #to_select:getPile("$zhangbao_zhou") == 0
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    target:addToPile("$zhangbao_zhou", effect.cards, false, zhoufu.name)
  end,
})

zhoufu:addEffect(fk.StartJudge, {
  can_refresh = function(self, event, target, player, data)
    return target == player and #player:getPile("$zhangbao_zhou") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.card = Fk:getCardById(player:getPile("$zhangbao_zhou")[1])
    data.card.skillName = zhoufu.name
  end,
})

return zhoufu
