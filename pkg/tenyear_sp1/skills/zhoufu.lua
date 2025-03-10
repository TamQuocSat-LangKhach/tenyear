local zhoufu = fk.CreateSkill {
  name = "ty__zhoufu"
}

Fk:loadTranslationTable{
  ['ty__zhoufu'] = '咒缚',
  ['#ty__zhoufu'] = '咒缚：将一张手牌置为一名角色的“咒缚”牌，其判定时改为将“咒缚”牌作为判定牌',
  ['ty__zhoufu_zhou'] = '咒',
  ['#ty__zhoufu_trigger'] = '咒缚',
  [':ty__zhoufu'] = '出牌阶段限一次，你可以将一张手牌置于一名没有“咒”的其他角色的武将牌旁，称为“咒”（当有“咒”的角色判定时，将“咒”作为判定牌）。',
  ['$ty__zhoufu1'] = '这束缚，可不是你能挣脱的！',
  ['$ty__zhoufu2'] = '咒术显灵，助我改运！'
}

zhoufu:addEffect('active', {
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#ty__zhoufu",
  can_use = function(self, player)
    return player:usedSkillTimes(zhoufu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(Self.player_cards[Player.Hand], to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select ~= Self.id and #Fk:currentRoom():getPlayerById(to_select):getPile("ty__zhoufu_zhou") == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    target:addToPile("ty__zhoufu_zhou", effect.cards, true, zhoufu.name, effect.from)
  end,
})

zhoufu:addEffect(fk.StartJudge, {
  can_refresh = function(self, event, player, data)
    return #player:getPile("ty__zhoufu_zhou") > 0
  end,
  on_refresh = function(self, event, player, data)
    data.card = Fk:getCardById(player:getPile("ty__zhoufu_zhou")[1])
  end,
})

return zhoufu
