local feibai = fk.CreateSkill {
  name = "ty__feibai",
}

Fk:loadTranslationTable{
  ["ty__feibai"] = "飞白",
  [":ty__feibai"] = "当你使用牌后，你可以从牌堆随机获得一张字数为X的牌（X为此牌与你本回合使用的上一张牌牌名字数之和，若没有上一张牌"..
  "则上一张字数视为0）。若没有字数为X的牌，你摸一张牌并标记为“弦”，此技能本回合失效。",

  ["$ty__feibai1"] = "",
  ["$ty__feibai2"] = "",
}

feibai:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(feibai.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = Fk:translate(data.card.trueName, "zh_CN"):len()
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function(e)
      if e.id < room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true).id then
        local use = e.data
        if use.from == player then
          n = n + Fk:translate(use.card.trueName, "zh_CN"):len()
          return true
        end
      end
    end, nil, Player.HistoryTurn)
    local cards = table.filter(room.draw_pile, function (id)
      return Fk:translate(Fk:getCardById(id).trueName, "zh_CN"):len() == n
    end)
    if #cards > 0 then
      room:obtainCard(player, table.random(cards), false, fk.ReasonJustMove, player, feibai.name)
    else
      player:drawCards(1, feibai.name, nil, player:hasSkill("jiaowei", true) and "@@jiaowei-inhand" or nil)
      room:invalidateSkill(player, feibai.name, "-turn")
    end
  end,
})

return feibai
