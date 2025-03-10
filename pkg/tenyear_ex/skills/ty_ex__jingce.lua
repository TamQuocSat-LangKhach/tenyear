local ty_ex__jingce = fk.CreateSkill {
  name = "ty_ex__jingce"
}

Fk:loadTranslationTable{
  ['ty_ex__jing__jingce'] = '精策',
  ['jingce_draw'] = '执行一个摸牌阶段',
  ['jingce_play'] = '执行一个出牌阶段',
  ['#ty_ex__jingce-active'] = '精策：选择执行一个额外的摸牌阶段或者出牌阶段',
  [':ty_ex__jingce'] = '结束阶段，若你本回合已使用的牌数大于或等于你的体力值，你可以选择：1.获得一个额外摸牌阶段；2.获得一个额外出牌阶段。若你本回合使用的牌花色也大于或等于你的体力值，则改为两项均执行。',
  ['$ty_ex__jingce1'] = '精细入微，策敌制胜。',
  ['$ty_ex__jingce2'] = '妙策如神，精兵强将，安有不胜之理？',
}

ty_ex__jingce:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player.phase == Player.Finish and player:hasSkill(ty_ex__jingce) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e)
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryTurn) >= player.hp
  end,
  on_use = function(self, event, target, player)
    local suits = {}
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e)
      local use = e.data[1]
      if use.from == player.id then
        table.insertIfNeed(suits, use.card.suit)
      end
    end, Player.HistoryTurn)

    if #suits >= player.hp then
      player:gainAnExtraPhase(Player.Play)
      player:gainAnExtraPhase(Player.Draw)
    else
      local choice = room:askToChoice(player, {
        choices = {"jingce_draw", "jingce_play"},
        skill_name = ty_ex__jingce.name,
        prompt = "#ty_ex__jingce-active"
      })
      if choice == "jingce_draw" then
        player:gainAnExtraPhase(Player.Draw)
      elseif choice == "jingce_play" then
        player:gainAnExtraPhase(Player.Play)
      end
    end
  end,
})

return ty_ex__jingce
