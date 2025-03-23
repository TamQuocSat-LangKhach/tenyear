local geyuan = fk.CreateSkill {
  name = "geyuan"
}

Fk:loadTranslationTable{
  ['geyuan'] = '割圆',
  ['@[geyuan]'] = '割圆',
  ['gusuan'] = '股算',
  ['#gusuan-choose'] = '割圆：依次点选至多三名角色，第一个摸3，第二个弃4，第三个换牌',
  ['#geyuan_start'] = '割圆',
  [':geyuan'] = '锁定技，游戏开始时，将A~K的所有点数随机排列成一个圆环。有牌进入弃牌堆时，将满足圆环进度的点数记录在圆环内。当圆环完成后，你获得牌堆和场上所有完成此圆环最初和最后点数的牌，然后从圆环中移除这两个点数（不会被移除到三个以下），重新开始圆环。<br><font color=>进度点数：圆环中即将被点亮的点数。</font>',
  ['$geyuan1'] = '绘同径之距，置内圆而割之。',
  ['$geyuan2'] = '矩割弥细，圆失弥少，以至不可割。',
}

-- 主技能效果
geyuan:addEffect(fk.AfterCardsMove, {
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(geyuan.name) then return false end
    local circle_data = player:getMark("@[geyuan]")
    if circle_data == 0 then return end
    local proceed = getCircleProceed(circle_data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local number = Fk:getCardById(info.cardId).number
          if table.contains(proceed, number) then return true end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local circle_data = player:getMark("@[geyuan]")
    local proceed = getCircleProceed(circle_data)
    local completed = false
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local number = Fk:getCardById(info.cardId).number
          if table.contains(proceed, number) then
            table.insert(circle_data.ok, number)
            proceed = getCircleProceed(circle_data)
            if proceed == Util.DummyTable then -- 已完成？
              completed = true
              goto BREAK
            end
          end
        end
      end
    end
    ::BREAK::

    if completed then
      local start, end_ = circle_data.ok[1], circle_data.ok[#circle_data.ok]
      local waked = player:usedSkillTimes("gusuan", Player.HistoryGame) > 0
      if waked then
        local players = room:askToChoosePlayers(player, {
          targets = table.map(room.alive_players, Util.IdMapper),
          min_num = 0,
          max_num = 3,
          prompt = "#gusuan-choose",
          skill_name = geyuan.name,
          cancelable = true
        })

        if players[1] then
          room:getPlayerById(players[1]):drawCards(3, geyuan.name)
        end
        if players[2] then
          local p = room:getPlayerById(players[2])
          room:askToDiscard(p, {
            min_num = 4,
            max_num = 4,
            include_equip = true,
            skill_name = geyuan.name,
            cancelable = false
          })
        end
        if players[3] then
          local p = room:getPlayerById(players[3])
          local cards = p:getCardIds(Player.Hand)
          room:moveCards({
            from = p.id,
            ids = cards,
            toArea = Card.Processing,
            moveReason = fk.ReasonExchange,
            proposer = player.id,
            skillName = geyuan.name,
            moveVisible = false,
          })
          if not p.dead then
            room:moveCardTo(room:getNCards(5, "bottom"), Card.PlayerHand, p, fk.ReasonExchange, geyuan.name, nil, false, player.id)
          end
          if #cards > 0 then
            table.shuffle(cards)
            room:moveCards({
              ids = cards,
              fromArea = Card.Processing,
              toArea = Card.DrawPile,
              moveReason = fk.ReasonExchange,
              skillName = geyuan.name,
              moveVisible = false,
              drawPilePosition = -1,
            })
          end
        end
      else
        local toget = {}
        for _, p in ipairs(room.alive_players) do
          for _, id in ipairs(p:getCardIds("ej")) do
            local c = Fk:getCardById(id, true)
            if c.number == start or c.number == end_ then
              table.insert(toget, c.id)
            end
          end
        end
        for _, id in ipairs(room.draw_pile) do
          local c = Fk:getCardById(id, true)
          if c.number == start or c.number == end_ then
            table.insert(toget, c.id)
          end
        end
        room:moveCardTo(toget, Card.PlayerHand, player, fk.ReasonPrey, geyuan.name, nil, true, player.id)
      end

      local all = circle_data.all
      if not waked then
        if #all > 3 then table.removeOne(all, start) end
        if #all > 3 then table.removeOne(all, end_) end
      end
      startCircle(player, all)
    else
      room:setPlayerMark(player, "@[geyuan]", circle_data)
    end
  end,
})

-- 刷新事件效果
geyuan:addEffect(fk.EventLoseSkill, {
  can_trigger = function(self, event, target, player, data)
    return player == target and data == geyuan.name
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[geyuan]", 0)
  end,
})

-- 开始游戏时的触发效果
geyuan:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(geyuan.name) and player:getMark("@[geyuan]") == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("geyuan")
    local points = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
    startCircle(player, points)
  end
})

return geyuan
