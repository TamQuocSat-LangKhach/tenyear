local shangyu = fk.CreateSkill {
  name = "shangyu"
}

Fk:loadTranslationTable{
  ['shangyu'] = '赏誉',
  ['#shangyu-give'] = '赏誉：将“赏誉”牌【%arg】交给一名角色',
  ['@@shangyu-inhand'] = '赏誉',
  [':shangyu'] = '锁定技，游戏开始时，你获得一张【杀】并标记之，然后可以将其交给一名角色。此【杀】：造成伤害后，你和使用者各摸一张牌；进入弃牌堆后，你将其交给一名本回合未以此法指定过的角色。',
  ['$shangyu1'] = '君满腹才学，当为国之大器。',
  ['$shangyu2'] = '一腔青云之志，正待梦日之时。',
}

shangyu:addEffect(fk.AfterCardsMove, {
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(shangyu.name) then return false end
    local cid = player:getMark("shangyu_slash")
    if player.room:getCardArea(cid) ~= Card.DiscardPile then return false end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if info.cardId == cid then
            return true
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, Util.IdMapper)
    local marks = player:getMark("shangyu_prohibit-turn")
    if type(marks) == "table" then
      targets = table.filter(targets, function (pid)
        return not table.contains(marks, pid)
      end)
    else
      marks = {}
    end
    if #targets == 0 then return false end
    local card = Fk:getCardById(player:getMark("shangyu_slash"))
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#shangyu-give:::" .. card:toLogString(),
      skill_name = shangyu.name
    })
    if #to > 0 then
      table.insert(marks, to[1])
      room:setPlayerMark(player, "shangyu_prohibit-turn", marks)
      room:moveCardTo(card, Card.PlayerHand, room:getPlayerById(to[1]), fk.ReasonGive, shangyu.name, nil, true, player.id)
    end
  end,
})

shangyu:addEffect(fk.Damage, {
  can_trigger = function (self, event, target, player, data)
    if not player:hasSkill(shangyu.name) then return false end
    if data.card and data.card.trueName == "slash" then
      local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
      if #cardlist == 1 and cardlist[1] == player:getMark("shangyu_slash") then
        local room = player.room
        local parentUseEvent = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if parentUseEvent then
          local use = parentUseEvent.data[1]
          local from = room:getPlayerById(use.from)
          if from and not from.dead then
            event:setCostData(self, use.from)
            return true
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local tar = room:getPlayerById(event:getCostData(self))
    room:doIndicate(player.id, {event:getCostData(self)})
    room:drawCards(player, 1, shangyu.name)
    if not tar.dead then
      room:drawCards(tar, 1, shangyu.name)
    end
  end,
})

shangyu:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("slash", 1)
    if #cards > 0 then
      local cid = cards[1]
      room:setPlayerMark(player, "shangyu_slash", cid)
      local card = Fk:getCardById(cid)
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, shangyu.name, nil, true, player.id)
      if player.dead or not table.contains(player:getCardIds(Player.Hand), cid) then return false end
      local to = room:askToChoosePlayers(player, {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#shangyu-give:::" .. card:toLogString(),
        skill_name = shangyu.name
      })
      if #to > 0 then
        room:moveCardTo(card, Card.PlayerHand, room:getPlayerById(to[1]), fk.ReasonGive, shangyu.name, nil, true, player.id)
      end
    end
  end,
})

shangyu:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return not player.dead and player:getMark("shangyu_slash") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local cid = player:getMark("shangyu_slash")
    local card = Fk:getCardById(cid)
    if room:getCardArea(cid) == Card.PlayerHand and card:getMark("@@shangyu-inhand") == 0 then
      room:setCardMark(Fk:getCardById(cid), "@@shangyu-inhand", 1)
    end
  end,
})

return shangyu
