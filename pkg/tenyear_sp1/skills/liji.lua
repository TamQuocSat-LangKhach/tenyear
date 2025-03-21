local liji = fk.CreateSkill {
  name = "liji"
}

Fk:loadTranslationTable{
  ['liji'] = '力激',
  ['@liji-turn'] = '力激',
  [':liji'] = '出牌阶段限零次，你可以弃置一张牌然后对一名其他角色造成1点伤害。你的回合内，本回合进入弃牌堆的牌每次达到8的倍数张时（存活人数小于5时改为4的倍数），此技能使用次数+1。',
  ['$liji1'] = '破敌搴旗，未尝负败！',
  ['$liiji2'] = '鸷猛壮烈，万人不敌！',
}

liji:addEffect('active', {
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  times = function(self, player)
    if player.phase == Player.Play then
      local mark = player:getTableMark("@liji-turn")
      return #mark > 0 and mark[1] or 0
    end
    return -1
  end,
  can_use = function(self, player)
    local mark = player:getTableMark("@liji-turn")
    return #mark > 0 and mark[1] > 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = player:getTableMark("@liji-turn")
    mark[1] = mark[1] - 1
    room:setPlayerMark(player, "@liji-turn", mark)
    room:throwCard(effect.cards, liji.name, player, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = liji.name,
    }
  end,
})

liji:addEffect('refresh', {
  events = {fk.TurnStart, fk.EventPhaseStart, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return player == target
    else
      return player.room.current == player and not player.dead and #player:getTableMark("@liji-turn") == 5
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.TurnStart then
      if player:hasSkill(liji.name, true) then
        room:setPlayerMark(player, "@liji-turn", {0, "-", 0, "/", #player.room.alive_players < 5 and 4 or 8})
      end
    elseif event == fk.EventPhaseStart then
      local mark = player:getTableMark("@liji-turn")
      mark[1] = player:getMark("liji_times-turn")
      room:setPlayerMark(player, "@liji-turn", mark)
    else
      local mark = player:getTableMark("@liji-turn")
      local x = mark[3]
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          x = x + #move.moveInfo
        end
      end
      mark[1] = mark[1] + math.floor(x / mark[5])
      room:addPlayerMark(player, "liji_times-turn", math.floor(x / mark[5]))
      mark[3] = x % mark[5]
      room:setPlayerMark(player, "@liji-turn", mark)
    end
  end,
})

return liji
