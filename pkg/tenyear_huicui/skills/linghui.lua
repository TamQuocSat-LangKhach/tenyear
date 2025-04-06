local linghui = fk.CreateSkill {
  name = "linghui",
}

Fk:loadTranslationTable{
  ["linghui"] = "灵慧",
  [":linghui"] = "一名角色的结束阶段，若其为你或有角色于本回合内进入过濒死状态，你可以观看牌堆顶的三张牌，你可以使用其中一张牌，"..
  "然后随机获得剩余牌中的一张。",

  ["#linghui-use"] = "灵慧：你可以使用其中的一张牌，然后获得剩余的随机一张",

  ["$linghui1"] = "福兮祸所依，祸兮福所伏。",
  ["$linghui2"] = "枯桑知风，沧海知寒。",
}

linghui:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(linghui.name) and target.phase == Player.Finish and
      (target == player or #player.room.logic:getEventsOfScope(GameEvent.Dying, 1, Util.TrueFunc, Player.HistoryTurn) > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3)
    room:turnOverCardsFromDrawPile(player, ids, linghui.name, false)
    local use = room:askToUseRealCard(player, {
      pattern = ids,
      skill_name = linghui.name,
      prompt = "#linghui-use",
      extra_data = {
        bypass_times = true,
        expand_pile = ids,
        extraUse = true,
      },
    })
    ids = table.filter(ids, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if not player.dead and use then
      if #ids > 0 then
        room:obtainCard(player, table.random(ids), false, fk.ReasonJustMove, player, linghui.name)
      end
    end
    room:returnCardsToDrawPile(player, ids, linghui.name, "top", false)
  end,
})

return linghui
