local tongliao = fk.CreateSkill {
  name = "tongliao"
}

Fk:loadTranslationTable{
  ['tongliao'] = '通辽',
  ['#tongliao-invoke'] = '通辽：你可以将一张点数最小的手牌标记为“通辽”牌',
  ['@@tongliao-inhand'] = '通辽',
  ['#tongliao_delay'] = '通辽',
  [':tongliao'] = '摸牌阶段结束时，你可以将手牌中点数最小的一张牌标记为“通辽”。当你失去“通辽”牌后，你摸X张牌（X为“通辽”牌的点数）。',
  ['$tongliao1'] = '发动偷袭。',
  ['$tongliao2'] = '不够心狠手辣，怎配江山如画。',
  ['$tongliao3'] = '必须出重拳，而且是物理意义上的出重拳。',
}

tongliao:addEffect(fk.EventPhaseEnd, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongliao.name) and player.phase == Player.Draw and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player.player_cards[Player.Hand], function(id)
      return table.every(player.player_cards[Player.Hand], function(id2)
        return Fk:getCardById(id).number <= Fk:getCardById(id2).number end) end)
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      pattern = ".|.|.|.|.|.|"..table.concat(ids, ","),
      prompt = "#tongliao-invoke",
    })
    if #cards > 0 then
      event:setCostData(self, cards[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self)
    room:addTableMarkIfNeed(player, "tongliao", id)
    room:setCardMark(Fk:getCardById(id), "@@tongliao-inhand", 1)
  end,
})

tongliao:addEffect(fk.AfterCardsMove, {
  name = "#tongliao_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead or type(player:getMark("tongliao")) ~= "table" then return false end
    local mark = player:getMark("tongliao")
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and table.contains(mark, info.cardId) then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "tongliao", "drawcard")
    player:broadcastSkillInvoke("tongliao")
    local mark = player:getMark("tongliao")
    local x = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and table.removeOne(mark, info.cardId) then
            x = x + Fk:getCardById(info.cardId).number
          end
        end
      end
    end
    room:setPlayerMark(player, "tongliao", #mark > 0 and mark or 0)
    if x > 0 then
      room:drawCards(player, x, tongliao.name)
    end
  end,
})

return tongliao
