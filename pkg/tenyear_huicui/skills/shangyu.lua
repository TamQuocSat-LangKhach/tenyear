local shangyu = fk.CreateSkill {
  name = "shangyu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shangyu"] = "赏誉",
  [":shangyu"] = "锁定技，游戏开始时，你获得一张【杀】并标记之，然后可以将之交给一名角色。此【杀】造成伤害后，你和使用者各摸一张牌；"..
  "进入弃牌堆后，你将之交给一名本回合未以此法选择过的角色。",

  ["#shangyu-give"] = "赏誉：将“赏誉”牌%arg交给一名角色",
  ["@@shangyu-inhand"] = "赏誉",

  ["$shangyu1"] = "君满腹才学，当为国之大器。",
  ["$shangyu2"] = "一腔青云之志，正待梦日之时。",
}

shangyu:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(shangyu.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("slash", 1)
    if #cards > 0 then
      local id = cards[1]
      room:setPlayerMark(player, "shangyu_slash", id)
      local card = Fk:getCardById(id)
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, shangyu.name, nil, true, player)
      if player.dead or not table.contains(player:getCardIds("h"), id)
        or #room:getOtherPlayers(player, false) == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#shangyu-give:::" .. card:toLogString(),
        skill_name = shangyu.name,
      })
      if #to > 0 then
        room:moveCardTo(card, Card.PlayerHand, to[1], fk.ReasonGive, shangyu.name, nil, true, player)
      end
    end
  end,
})

shangyu:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(shangyu.name) and player:getMark("shangyu_slash") ~= 0 and
      table.find(player.room.alive_players, function (p)
        return not table.contains(player:getTableMark("shangyu-turn"), p.id)
      end) then
      local id = player:getMark("shangyu_slash")
      if not table.contains(player.room.discard_pile, id) then return false end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.cardId == id then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not table.contains(player:getTableMark("shangyu-turn"), p.id)
    end)
    local card = Fk:getCardById(player:getMark("shangyu_slash"))
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#shangyu-give:::" .. card:toLogString(),
      skill_name = shangyu.name,
      cancelable = false,
    })[1]
    room:addTableMark(player, "shangyu-turn", to.id)
    room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, shangyu.name, nil, true, player)
  end,

  can_refresh = function (self, event, target, player, data)
    return not player.dead and player:getMark("shangyu_slash") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local id = player:getMark("shangyu_slash")
    if room:getCardArea(id) == Card.PlayerHand then
      room:setCardMark(Fk:getCardById(id), "@@shangyu-inhand", 1)
    end
  end,
})

shangyu:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(shangyu.name) and player:getMark("shangyu_slash") ~= 0 and target and
      data.card and data.card.trueName == "slash" and
      #Card:getIdList(data.card) == 1 and Card:getIdList(data.card)[1] == player:getMark("shangyu_slash") then
        local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if use_event then
          local use = use_event.data
          if not use.from.dead then
            event:setCostData(self, {tos = {use.from}})
            return true
          end
        end
      end
  end,
  on_use = function (self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    player:drawCards(1, shangyu.name)
    if not to.dead then
      to:drawCards(1, shangyu.name)
    end
  end,
})

return shangyu
