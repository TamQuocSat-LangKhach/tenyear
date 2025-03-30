local qianxin = fk.CreateSkill {
  name = "qianxinz",
}

Fk:loadTranslationTable{
  ["qianxinz"] = "遣信",
  [":qianxinz"] = "出牌阶段限一次，若牌堆中没有“信”，你可以选择一名角色并将任意张手牌置于牌堆中X倍数的位置（X为存活人数），称为“信”。"..
  "该角色弃牌阶段开始时，若其手牌中有本回合获得的“信”，其选择一项：1.你将手牌摸至四张；2.其本回合手牌上限-2。",

  ["#qianxinz"] = "遣信：选择“遣信”目标，将任意张手牌作为“信”置入牌堆",
  ["@@qianxinz"] = "遣信",
  ["@@zhanggong_mail"] = "信",
  ["qianxinz1"] = "%src将手牌摸至四张",
  ["qianxinz2"] = "你本回合手牌上限-2",

  ["$qianxinz1"] = "遣信求援，前后合围。",
  ["$qianxinz2"] = "信中所言，吾知计策一二。",
}

qianxin:addEffect("active", {
  anim_type = "control",
  prompt = "#qianxinz",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not table.find(Fk:currentRoom().draw_pile, function (id)
      return Fk:getCardById(id):getMark("@@zhanggong_mail") ~= 0
    end)
  end,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select) and
      #selected < #Fk:currentRoom().draw_pile // #Fk:currentRoom().alive_players
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local moveInfos = {}
    local position = 1
    table.shuffle(effect.cards)
    for _, id in ipairs(effect.cards) do
      table.insert(moveInfos, {
        ids = {id},
        from = player,
        fromArea = Card.PlayerHand,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = qianxin.name,
        drawPilePosition = position * #room.alive_players,
      })
      position = position + 1
    end
    room:moveCards(table.unpack(moveInfos))
    if player:hasSkill(qianxin.name, true) and not target.dead then
      room:addTableMark(target, "@@qianxinz", player.id)
      for _, id in ipairs(effect.cards) do
        room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", {player.id, target.id})
      end
    end
  end,
})

qianxin:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(qianxin.name, true) and target.phase == Player.Discard and
      table.find(target:getCardIds("h"), function(id)
        local mark = Fk:getCardById(id):getMark("@@zhanggong_mail")
        return mark ~= 0 and mark[1] == player.id and mark[2] == target.id
      end)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(target:getCardIds("h")) do
      local mark = Fk:getCardById(id):getMark("@@zhanggong_mail")
      if mark ~= 0 and mark[1] == player.id and mark[2] == target.id then
        room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", 0)
      end
    end
    if table.every(Fk:getAllCardIds(), function(id)
      return Fk:getCardById(id):getMark("@@zhanggong_mail") == 0
    end) then
      room:setPlayerMark(target, "@@qianxinz", 0)
    end
    local choices = {"qianxinz2"}
    if player:getHandcardNum() < 4 then
      table.insert(choices, 1, "qianxinz1:"..player.id)
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = qianxin.name,
      all_choices = {"qianxinz1:" .. player.id, "qianxinz2"}
    })
    if choice ~= "qianxinz2" then
      player:drawCards(4 - player:getHandcardNum(), qianxin.name)
    else
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, 2)
    end
  end,
})

qianxin:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(Fk:getAllCardIds()) do
    local mark = Fk:getCardById(id):getMark("@@zhanggong_mail")
    if mark ~= 0 and mark[1] == player.id then
      room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", 0)
    end
  end
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, "@@qianxinz", player.id)
  end
end)

qianxin:addEffect(fk.Death, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@qianxinz") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    for _, id in ipairs(Fk:getAllCardIds()) do
      local mark = Fk:getCardById(id):getMark("@@zhanggong_mail")
      if mark ~= 0 and mark[2] == player.id then
        player.room:setCardMark(Fk:getCardById(id), "@@zhanggong_mail", 0)
      end
    end
  end,
})

qianxin:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(qianxin.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      for _, info in ipairs(move.moveInfo) do
        local mark = Fk:getCardById(info.cardId):getMark("@@zhanggong_mail")
        if mark ~= 0 and mark[1] == player.id then
          if move.to == nil or move.to.id ~= mark[2] or move.toArea ~= Card.PlayerHand then
            room:setCardMark(Fk:getCardById(info.cardId), "@@zhanggong_mail", 0)
          end
        end
      end
    end
    if table.every(Fk:getAllCardIds(), function(id)
      local mark = Fk:getCardById(id):getMark("@@zhanggong_mail")
      return mark == 0 or mark[1] ~= player.id
    end) then
      for _, p in ipairs(room.alive_players) do
        room:removeTableMark(p, "@@qianxinz", player.id)
      end
    end
  end,
})

return qianxin
