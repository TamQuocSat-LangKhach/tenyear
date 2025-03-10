local pingxi = fk.CreateSkill {
  name = "pingxi"
}

Fk:loadTranslationTable{
  ['pingxi'] = '平袭',
  ['#pingxi-choose'] = '平袭：你可以选择至多%arg名角色，弃置这些角色各一张牌并视为对这些角色各使用一张【杀】',
  [':pingxi'] = '结束阶段，你可以选择至多X名其他角色（X为本回合因弃置而进入弃牌堆的牌数），弃置这些角色各一张牌（无牌则不弃），然后视为对这些角色各使用一张【杀】。',
  ['$pingxi1'] = '地有常险，守无常势。',
  ['$pingxi2'] = '国有常众，战无常胜。',
}

pingxi:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(pingxi.name) and player.phase == Player.Finish and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
            return true
          end
        end
      end, Player.HistoryTurn) > 0 and
      table.find(player.room:getOtherPlayers(player), function(p)
        return not p:isNude() or not player:isProhibited(p, Fk:cloneCard("slash"))
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local n = 0
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
          n = n + #move.moveInfo
        end
      end
    end, Player.HistoryTurn)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() or not player:isProhibited(p, Fk:cloneCard("slash"))
    end), Util.IdMapper)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = n,
      targets = targets,
      skill_name = pingxi.name,
      prompt = "#pingxi-choose:::" .. n
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local tos = event:getCostData(self).tos
    room:sortPlayersByAction(tos)
    for _, id in ipairs(tos) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p:isNude() and not p.dead then
        local card = room:askToChooseCard(player, {
          target = p,
          flag = "he",
          skill_name = pingxi.name
        })
        room:throwCard(card, pingxi.name, p, player)
      end
    end
    for _, id in ipairs(tos) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        room:useVirtualCard("slash", nil, player, p, pingxi.name, true)
      end
    end
  end,
})

return pingxi
