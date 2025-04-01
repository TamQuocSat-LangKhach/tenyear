local haoyi = fk.CreateSkill {
  name = "haoyi",
}

Fk:loadTranslationTable{
  ["haoyi"] = "豪义",
  [":haoyi"] = "结束阶段，你可以获得弃牌堆中所有本回合进入且未造成过伤害的伤害类牌，然后可以任意分配给其他角色。",

  ["#haoyi-give"] = "豪义：你可以将这些牌分配给其他角色",

  ["$haoyi1"] = "今缴丧敌之炙，且宴麾下袍泽。",
  ["$haoyi2"] = "龙骧枯荣一体，岂曰同袍无衣。",
}

haoyi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(haoyi.name) and player.phase == Player.Finish then
      local room = player.room
      local cards = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if room:getCardArea(info.cardId) == Card.DiscardPile and Fk:getCardById(info.cardId, true).is_damage_card then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end, Player.HistoryTurn)
      if #cards == 0 then return false end
      room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data
        if damage.card then
          for _, id in ipairs(Card:getIdList(damage.card)) do
            if table.removeOne(cards, id) and #cards == 0 then
              return true
            end
          end
        end
      end, Player.HistoryTurn)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(self).cards)
    room:obtainCard(player, cards, true, fk.ReasonJustMove, player, haoyi.name)
    if player.dead then return end
    cards = table.filter(player:getCardIds("h"), function (id)
      return table.contains(cards, id)
    end)
    if #cards > 0 and #player.room:getOtherPlayers(player, false) > 0 then
      room:askToYiji(player, {
        cards = cards,
        targets = room.alive_players,
        skill_name = haoyi.name,
        min_num = 0,
        max_num = 999,
        prompt = "#haoyi-give",
      })
    end
  end,
})

return haoyi
