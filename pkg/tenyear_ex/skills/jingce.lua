local jingce = fk.CreateSkill {
  name = "ty_ex__jingce",
}

Fk:loadTranslationTable{
  ["ty_ex__jingce"] = "精策",
  [":ty_ex__jingce"] = "结束阶段，若你本回合使用的牌数不小于体力值，你可以执行一个额外摸牌阶段或出牌阶段。若花色数也不小于体力值，"..
  "则两项均执行。",

  ["#ty_ex__jingce-choice"] = "精策：选择执行的额外阶段",

  ["$ty_ex__jingce1"] = "精细入微，策敌制胜。",
  ["$ty_ex__jingce2"] = "妙策如神，精兵强将，安有不胜之理？",
}

jingce:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jingce.name) and player.phase == Player.Finish and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, player.hp, function(e)
        return e.data.from == player
      end, Player.HistoryTurn) == player.hp
  end,
  on_use = function(self, event, target, player, data)
    local suits = {}
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.UseCard, player.hp, function(e)
      local use = e.data
      if use.from == player then
        table.insertIfNeed(suits, use.card.suit)
      end
    end, Player.HistoryTurn)
    table.removeOne(suits, Card.NoSuit)
    if #suits >= player.hp then
      player:gainAnExtraPhase(Player.Play)
      player:gainAnExtraPhase(Player.Draw)
    else
      local choice = room:askToChoice(player, {
        choices = {"phase_draw", "phase_play"},
        skill_name = jingce.name,
        prompt = "#ty_ex__jingce-choice",
      })
      if choice == "phase_draw" then
        player:gainAnExtraPhase(Player.Draw)
      elseif choice == "phase_play" then
        player:gainAnExtraPhase(Player.Play)
      end
    end
  end,
})

return jingce
