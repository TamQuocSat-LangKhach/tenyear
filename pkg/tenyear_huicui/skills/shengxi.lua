local shengxi = fk.CreateSkill {
  name = "ty__shengxi",
}

Fk:loadTranslationTable{
  ["ty__shengxi"] = "生息",
  [":ty__shengxi"] = "结束阶段，若你于此回合内未造成过伤害，你可以摸两张牌。",

  ["$ty__shengxi1"] = "国之生计，在民生息。",
  ["$ty__shengxi2"] = "安民止战，兴汉室！",
}

shengxi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shengxi.name) and player.phase == Player.Finish and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == player
      end) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, shengxi.name)
  end,
})

return shengxi
