local tongliao = fk.CreateSkill {
  name = "tongliao",
}

Fk:loadTranslationTable{
  ["tongliao"] = "通辽",
  [":tongliao"] = "摸牌阶段结束时，你可以将手牌中点数最小的一张牌标记为“通辽”。当你失去“通辽”牌后，你摸X张牌（X为“通辽”牌的点数）。",

  ["#tongliao-invoke"] = "通辽：将一张点数最小的手牌标记为“通辽”，失去后摸牌",
  ["@@tongliao-inhand"] = "通辽",

  ["$tongliao1"] = "发动偷袭。",
  ["$tongliao2"] = "不够心狠手辣，怎配江山如画。",
  ["$tongliao3"] = "必须出重拳，而且是物理意义上的出重拳。",
}

tongliao:addEffect(fk.EventPhaseEnd, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongliao.name) and player.phase == Player.Draw and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("h"), function(id)
      return table.every(player:getCardIds("h"), function(id2)
        return Fk:getCardById(id).number <= Fk:getCardById(id2).number
      end)
    end)
    local cards = room:askToCards(player, {
      skill_name = tongliao.name,
      min_num = 1,
      max_num = 1,
      include_equip = false,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#tongliao-invoke",
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self).cards[1]
    room:addTableMarkIfNeed(player, tongliao.name, id)
    room:setCardMark(Fk:getCardById(id), "@@tongliao-inhand", 1)
  end,
})

tongliao:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark(tongliao.name) ~= 0 and not player.dead then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and table.contains(player:getTableMark(tongliao.name), info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = 0
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and
            room:removeTableMark(player, tongliao.name, info.cardId) then
            x = x + Fk:getCardById(info.cardId).number
          end
        end
      end
    end
    if x > 0 then
      player:drawCards(x, tongliao.name)
    end
  end,
})

tongliao:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, tongliao.name, 0)
end)

return tongliao
