local haoyi = fk.CreateSkill {
  name = "haoyi"
}

Fk:loadTranslationTable{
  ['haoyi'] = '豪义',
  [':haoyi'] = '结束阶段，你可以获得弃牌堆里于此回合内移至此区域的未造成过伤害的所有伤害类牌，然后你可以将这些牌中的任意张交给其他角色。',
  ['$haoyi1'] = '今缴丧敌之炙，且宴麾下袍泽。',
  ['$haoyi2'] = '龙骧枯荣一体，岂曰同袍无衣。',
}

haoyi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(haoyi.name) and player.phase == Player.Finish then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      local end_id = turn_event.id
      local cards = {}
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if room:getCardArea(info.cardId) == Card.DiscardPile and Fk:getCardById(info.cardId, true).is_damage_card then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
        return false
      end, end_id)
      if #cards == 0 then return false end
      local damage
      room.logic:getActualDamageEvents(1, function (e)
        damage = e.data[1]
        if damage.card then
          for _, id in ipairs(Card:getIdList(damage.card)) do
            if table.removeOne(cards, id) and #cards == 0 then
              return true
            end
          end
        end
      end, nil, end_id)
      if #cards > 0 then
        event:setCostData(skill, cards)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(skill))
    room:obtainCard(player, cards, true, fk.ReasonJustMove, player.id, haoyi.name)
    if player.dead then return false end
    cards = table.filter(player:getCardIds(Player.Hand), function (id)
      return table.contains(cards, id)
    end)
    if #cards > 0 then
      room:askToYiji(player, {
        cards = cards,
        targets = room:getOtherPlayers(player),
        skill_name = haoyi.name
      })
    end
  end,
})

return haoyi
