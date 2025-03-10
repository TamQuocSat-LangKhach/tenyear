local qianxinz = fk.CreateSkill {
  name = "qianxinz"
}

Fk:loadTranslationTable{
  ['qianxinz'] = '遣信',
  ['#qianxinz'] = '遣信：选择“遣信”目标，将任意张手牌作为“信”置入牌堆',
  ['@@zhanggong_mail'] = '信',
  ['qianxinz2'] = '你本回合手牌上限-2',
  ['qianxinz1'] = '%src将手牌摸至四张',
  [':qianxinz'] = '出牌阶段限一次，若牌堆中没有“信”，你可以选择一名角色并将任意张手牌置于牌堆中X倍数的位置（X为存活人数），称为“信”。该角色弃牌阶段开始时，若其手牌中有本回合获得的“信”，其选择一项：1.你将手牌摸至四张；2.其本回合手牌上限-2。',
  ['$qianxinz1'] = '遣信求援，前后合围。',
  ['$qianxinz2'] = '信中所言，吾知计策一二。',
}

-- 主动技能
qianxinz:addEffect('active', {
  anim_type = "control",
  prompt = "#qianxinz",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("qianxinz_canuse") > 0
  end,
  card_filter = function(self, player, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Player.Hand and
      #selected < player:getMark("qianxinz_canuse") // (#Fk:currentRoom().alive_players - 1)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local moveInfos = {}
    local n = #room.draw_pile // #room.alive_players
    local position = 1
    table.shuffle(effect.cards)
    for _, id in ipairs(effect.cards) do
      table.insert(moveInfos, {
        ids = {id},
        from = player.id,
        fromArea = Card.PlayerHand,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = qianxinz.name,
        drawPilePosition = position * #room.alive_players
      })
      position = position + 1
    end
    room:moveCards(table.unpack(moveInfos))
    room:setPlayerMark(player, "qianxinz_using", 1)
    room:setPlayerMark(target, "@@zhanggong_mail", 1)
    for _, id in ipairs(effect.cards) do
      room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", 1)
    end
  end,
})

-- 触发技能
qianxinz:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function (skill, event, target, player)
    return player:getMark("qianxinz_using") > 0 and target:getMark("@@zhanggong_mail") > 0 and target.phase == Player.Discard and
      table.find(target:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@zhanggong_mail") > 0 end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (skill, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke("qianxinz")
    room:notifySkillInvoked(player, "qianxinz", "control")
    room:doIndicate(player.id, {target.id})
    for _, id in ipairs(target:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", 0)
    end
    if table.every(Fk:getAllCardIds(), function(id) return Fk:getCardById(id):getMark("@@zhanggong_mail") == 0 end) then
      room:setPlayerMark(player, "qianxinz_using", 0)
      room:setPlayerMark(target, "@@zhanggong_mail", 0)
    end
    local choices = {"qianxinz2"}
    if player:getHandcardNum() < 4 then
      table.insert(choices, 1, "qianxinz1:"..player.id)
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = "qianxinz",
      all_choices = {"qianxinz1:" .. player.id, "qianxinz2"}
    })
    if choice ~= "qianxinz2" then
      player:drawCards(4 - player:getHandcardNum(), qianxinz.name)
    else
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 2)
    end
  end,
})

-- 刷新技能
qianxinz:addEffect({
  refresh_events = {fk.StartPlayCard, fk.AfterCardsMove, fk.Death, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.StartPlayCard then
      return target == player and player:hasSkill(qianxinz.name)
    elseif event == fk.AfterCardsMove and player:getMark("qianxinz_using") > 0 then
      local room = player.room
      for _, move in ipairs(data) do
        if not move.to or move.toArea ~= Card.PlayerHand or
          room:getPlayerById(move.to):getMark("@@zhanggong_mail") == 0 or
          room:getPlayerById(move.to).phase == Player.NotActive then
          return true
        end
      end
    elseif event == fk.Death then
      return target == player and player:getMark("qianxinz_using") > 0
    elseif event == fk.EventLoseSkill then
      return data == qianxinz.name and player:getMark("qianxinz_using") > 0
    end
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    if event == fk.StartPlayCard then
      if table.find(room.draw_pile, function(id) return Fk:getCardById(id):getMark("@@zhanggong_mail") > 0 end) then
        room:setPlayerMark(player, "qianxinz_canuse", 0)
      else
        room:setPlayerMark(player, "qianxinz_canuse", #room.draw_pile)
      end
    elseif event == fk.AfterCardsMove then
      local to = table.filter(room.alive_players, function(p) return p:getMark("@@zhanggong_mail") > 0 end)
      if #to == 0 then
        room:setPlayerMark(player, "qianxinz_using", 0)
        for _, id in ipairs(Fk:getAllCardIds()) do
          room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", 0)
        end
      else
        to = to[1]
        for _, move in ipairs(data) do
          if not move.to or move.to ~= to.id or move.toArea ~= Card.PlayerHand or to.phase == Player.NotActive then
            for _, info in ipairs(move.moveInfo) do
              room:setCardMark(Fk:getCardById(info.cardId), "@@zhanggong_mail", 0)
            end
          end
        end
        if table.every(Fk:getAllCardIds(), function(id) return Fk:getCardById(id):getMark("@@zhanggong_mail") == 0 end) then
          room:setPlayerMark(player, "qianxinz_using", 0)
          room:setPlayerMark(to, "@@zhanggong_mail", 0)
        end
      end
    else
      for _, p in ipairs(room.alive_players) do
        room:setPlayerMark(p, "@@zhanggong_mail", 0)
      end
      for _, id in ipairs(Fk:getAllCardIds()) do
        room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", 0)
      end
    end
  end,
})

return qianxinz
