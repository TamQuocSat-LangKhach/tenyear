local chenyong = fk.CreateSkill{
  name = "chenyong",
}

Fk:loadTranslationTable{
  ["chenyong"] = "沉勇",
  [":chenyong"] = "结束阶段，你可以摸X张牌（X为本回合你使用过牌的类型数）。",

  ["$chenyong1"] = "将者，当泰山崩于前而不改色。",
  ["$chenyong2"] = "救将陷之城，焉求益兵之助。",
}

chenyong:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chenyong.name) and player.phase == Player.Finish and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    local types = {}
    player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      if e.data.from == player then
        table.insertIfNeed(types, e.data.card.type)
      end
    end, Player.HistoryTurn)
    player:drawCards(#types, chenyong.name)
  end,
})

return chenyong
