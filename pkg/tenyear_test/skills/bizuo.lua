local bizuo = fk.CreateSkill{
  name = "bizuo",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["bizuo"] = "弼佐",
  [":bizuo"] = "限定技，一名角色回合结束时，若一号位角色体力值为全场最低，你可以令一名角色执行一个额外回合：此回合中除你与其以外的角色"..
  "非锁定技失效；此回合结束时，你分配本回合所有不因弃置进入弃牌堆的牌。",

  ["#bizuo-choose"] = "弼佐：令一名角色执行一个额外回合！",
  ["@@bizuo-turn"] = "弼佐",
  ["#bizuo-give"] = "弼佐：分配本回合所有不因弃置进入弃牌堆的牌！",

  ["$bizuo1"] = "",
  ["$bizuo2"] = "",
}

bizuo:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(bizuo.name) and
      player:usedSkillTimes(bizuo.name, Player.HistoryGame) == 0 and
      table.every(player.room.alive_players, function (p)
        return p.hp >= player.room:getPlayerBySeat(1).hp
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#bizuo-choose",
      skill_name = bizuo.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMark(to, bizuo.name, player.id)
    to:gainAnExtraTurn(true, bizuo.name)
  end,
})

bizuo:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.reason == bizuo.name
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local src = player:getMark(bizuo.name)[1]
    room:setPlayerMark(player, "@@bizuo-turn", src)
    room:removeTableMark(player, bizuo.name, src)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.id ~= src then
        room:addPlayerMark(p, MarkEnum.UncompulsoryInvalidity.."-turn", 1)
      end
    end
  end,
})

bizuo:addEffect(fk.TurnEnd, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target:getMark("@@bizuo-turn") == player.id and not player.dead then
      local cards = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end, Player.HistoryTurn)
      cards = table.filter(cards, function (id)
        return table.contains(player.room.discard_pile, id)
      end)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    room:askToYiji(player, {
      min_num = #cards,
      max_num = #cards,
      skill_name = bizuo.name,
      targets = room.alive_players,
      cards = cards,
      prompt = "#bizuo-give",
      expand_pile = cards,
    })
  end,
})

return bizuo
