local liuliFuli = fk.CreateSkill {
  name = "liuli__fuli"
}

Fk:loadTranslationTable{
  ['liuli__fuli'] = '抚黎',
  ['#liuli__fuli_ex-choose'] = '抚黎：你可以选择一名角色，令其攻击范围减至0直到你的下个回合开始',
  ['#liuli__fuli-choose'] = '抚黎：你可以选择一名角色，令其攻击范围-1直到你的下个回合开始',
  ['@liuli__fuli'] = '抚黎',
  [':liuli__fuli'] = '出牌阶段限一次，你可以展示所有手牌，选择其中有的一种类别的所有牌弃置，然后摸X张牌（X为以此法弃置的牌的牌名字数之和，且至多为场上手牌最多的角色的手牌数），且你可令一名角色的攻击范围-1直到你的下个回合开始。若以此法弃置了伤害牌，则改为其攻击范围减至0直至你的下个回合开始。',
  ['$liuli__fuli1'] = '民为贵，社稷次之，君为轻。',
  ['$liuli__fuli2'] = '民之所欲，天必从之。',
}

liuliFuli:addEffect('active', {
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(liuliFuli.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    if from:isKongcheng() then
      return
    end

    from:showCards(from:getCardIds("h"))
    local types = {}
    for _, id in ipairs(from:getCardIds("h")) do
      table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
    end

    if #types > 0 then
      local choice = room:askToChoice(from, {choices = types, skill_name = liuliFuli.name})
      local toDiscard = table.filter(from:getCardIds("h"), function(id)
        local card = Fk:getCardById(id)
        return card:getTypeString() == choice and not from:prohibitDiscard(card)
      end)

      if #toDiscard == 0 then
        return
      end

      local cardNameLength = 0
      local hasDMGCard = false
      for _, cardId in ipairs(toDiscard) do
        local card = Fk:getCardById(cardId)
        cardNameLength = cardNameLength + Fk:translate(card.trueName):len() -- FIXME: depends on config language, catastrophe!

        if card.is_damage_card then
          hasDMGCard = true
        end
      end

      room:throwCard(toDiscard, liuliFuli.name, from, from)

      local maxHandCardsNum = 0
      for _, p in ipairs(room.alive_players) do
        if maxHandCardsNum < p:getHandcardNum() then
          maxHandCardsNum = p:getHandcardNum()
        end
      end

      from:drawCards(math.min(maxHandCardsNum, cardNameLength), liuliFuli.name)

      local toIds = room:askToChoosePlayers(from, {
        targets = table.map(room.alive_players, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = hasDMGCard and "#liuli__fuli_ex-choose" or "#liuli__fuli-choose",
        skill_name = liuliFuli.name
      })

      if #toIds > 0 then
        local to = room:getPlayerById(toIds[1])
        local num = hasDMGCard and to:getAttackRange() or 1

        if num > 0 then
          room:setPlayerMark(to, "@liuli__fuli", to:getMark("@liuli__fuli") - num)
          from.tag["liuliFuliPlayers"] = from.tag["liuliFuliPlayers"] or {}
          from.tag["liuliFuliPlayers"][to.id] = (from.tag["liuliFuliPlayers"][to.id] or 0) + num
        end
      end
    end
  end,
})

liuliFuli:addEffect('trigger', {
  events = {fk.TurnStart, fk.Death},
  can_refresh = function(self, event, target, player)
    local room = player.room
    return
      target == player and
      player.tag["liuliFuliPlayers"] and
      table.find(room.alive_players, function(p) return p:getMark("@liuli__fuli") ~= 0 end)
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    for playerId, num in pairs(player.tag["liuliFuliPlayers"]) do
      local player = room:getPlayerById(playerId)
      if player:getMark("@liuli__fuli") ~= 0 then
        room:setPlayerMark(player, "@liuli__fuli", math.min(player:getMark("@liuli__fuli") + num, 0))
      end
    end

    player.tag["liuliFuliPlayers"] = nil
  end,
})

liuliFuli:addEffect('atkrange', {
  correct_func = function (self, from)
    return from:getMark("@liuli__fuli")
  end,
})

return liuliFuli
