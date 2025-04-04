local yaner = fk.CreateSkill {
  name = "yaner",
}

Fk:loadTranslationTable{
  ["yaner"] = "燕尔",
  [":yaner"] = "每回合限一次，当其他角色于其出牌阶段内失去最后的手牌后，你可以与其各摸两张牌，然后若因此摸到相同类型的两张牌的角色为："..
  "你，〖织纴〗改为回合外也可以发动直到你的下个回合开始；其，其回复1点体力。",

  ["#yaner-invoke"] = "燕尔：你可以与 %dest 各摸两张牌",
  ["@@yaner"] = "燕尔",

  ["$yaner1"] = "如胶似漆，白首相随。",
  ["$yaner2"] = "新婚燕尔，亲睦和美。",
}

yaner:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yaner.name) and player:usedSkillTimes(yaner.name, Player.HistoryTurn) == 0 and
      player.room.current:isKongcheng() and player.room.current.phase == Player.Play and not player.room.current.dead then
      for _, move in ipairs(data) do
        if move.from == player.room.current then
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
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yaner.name,
      prompt = "#yaner-invoke::"..room.current.id,
    }) then
      event:setCostData(self, {tos = {room.current}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room.current
    local cards = player:drawCards(2, yaner.name)
    if #cards == 2 and Fk:getCardById(cards[1]).type == Fk:getCardById(cards[2]).type and player:hasSkill("zhiren", true) then
      room:setPlayerMark(player, "@@yaner", 1)
    end
    if to.dead then return end
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
})

yaner:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yaner") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yaner", 0)
  end,
})

return yaner
