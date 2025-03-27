local yaner = fk.CreateSkill {
  name = "yaner"
}

Fk:loadTranslationTable{
  ['yaner'] = '燕尔',
  ['#yaner-invoke'] = '燕尔：你可以与 %dest 各摸两张牌，若摸到的牌类型形同则获得额外效果',
  ['@@yaner'] = '燕尔',
  [':yaner'] = '每回合限一次，当其他角色于其出牌阶段内失去最后的手牌后，你可以与其各摸两张牌，然后若因此摸到相同类型的两张牌的角色为：你，〖织纴〗改为回合外也可以发动直到你的下个回合开始；其，其回复1点体力。',
  ['$yaner1'] = '如胶似漆，白首相随。',
  ['$yaner2'] = '新婚燕尔，亲睦和美。',
}

yaner:addEffect(fk.AfterCardsMove, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yaner.name) and player:usedSkillTimes(yaner.name, Player.HistoryTurn) == 0 then
      local current = player.room.current
      if current == player or current.dead or current.phase ~= Player.Play or not current:isKongcheng() then
        return false
      end
      for _, move in ipairs(data) do
        if move.from == current.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yaner.name,
      prompt = "#yaner-invoke::" .. player.room.current.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room.current
    room:doIndicate(player.id, {to.id})
    local cards = player:drawCards(2, yaner.name)
    if #cards == 2 and Fk:getCardById(cards[1]).type == Fk:getCardById(cards[2]).type then
      room:setPlayerMark(player, "@@yaner", 1)
    end
    if to.dead then return false end
    cards = to:drawCards(2, yaner.name)
    if not to.dead and to:isWounded()
      and #cards == 2 and Fk:getCardById(cards[1]).type == Fk:getCardById(cards[2]).type then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = yaner.name
      }
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yaner") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yaner", 0)
  end,
})

return yaner
