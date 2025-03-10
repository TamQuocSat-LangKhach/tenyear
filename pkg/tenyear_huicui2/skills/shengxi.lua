local shengxi = fk.CreateSkill {
  name = "ty__shengxi"
}

Fk:loadTranslationTable{
  ['ty__shengxi'] = '生息',
  [':ty__shengxi'] = '结束阶段，若你于此回合内未造成过伤害，你可摸两张牌。',
  ['$ty__shengxi1'] = '国之生计，在民生息。',
  ['$ty__shengxi2'] = '安民止战，兴汉室！',
}

shengxi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return player == target and player:hasSkill(shengxi.name) and player.phase == Player.Finish and
      #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == player end) == 0
  end,
  on_use = function(self, event, target, player)
    player:drawCards(2, shengxi.name)
  end,
})

return shengxi
