local manwang = fk.CreateSkill {
  name = "ty__manwang"
}

Fk:loadTranslationTable{
  ['ty__manwang'] = '蛮王',
  ['#ty__manwang-prompt'] = '蛮王：弃置任意张牌，依次执行〖蛮王〗的前等量项（剩余 %arg 项）',
  ['@[:]ty__manwang'] = '蛮王',
  ['ty__manwang1'] = '蛮王1',
  ['ty__manwang2'] = '蛮王2',
  ['ty__manwang3'] = '蛮王3',
  ['ty__manwang4'] = '蛮王4',
  [':ty__manwang'] = '出牌阶段，你可以弃置任意张牌依次执行前等量项：1.获得〖叛侵〗；2.摸一张牌；3.回复1点体力；4.摸两张牌并失去〖叛侵〗。',
}

manwang:addEffect('active', {
  anim_type = "special",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  prompt = function (skill, player)
    return "#ty__manwang-prompt:::"..(#player:getTableMark("@[:]ty__manwang"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, manwang.name, player, player)
    for i = 1, #effect.cards, 1 do
      if i > 4 or i > #player:getTableMark("@[:]ty__manwang") or player.dead then return end
      doManwang(player, i)
    end
  end,
})

manwang:addEffect('acquire', {
  on_acquire = function (skill, player)
    player.room:setPlayerMark(player, "@[:]ty__manwang", {"ty__manwang1", "ty__manwang2", "ty__manwang3", "ty__manwang4"})
  end,
})

manwang:addEffect('lose', {
  on_lose = function (skill, player)
    player.room:setPlayerMark(player, "@[:]ty__manwang", 0)
  end,
})

return manwang
