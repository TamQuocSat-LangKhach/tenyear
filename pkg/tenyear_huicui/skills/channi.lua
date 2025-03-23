local channi = fk.CreateSkill {
  name = "channi"
}

Fk:loadTranslationTable{
  ['channi'] = '谗逆',
  ['#channi-active'] = '发动 谗逆，将任意数量的手牌交给一名角色',
  ['channi_viewas'] = '谗逆',
  ['#channi-invoke'] = '谗逆：你可以将至多%arg张手牌当一张【决斗】使用<br>若对目标造成伤害你摸等量牌，若你受到伤害则 %src 弃置所有手牌',
  ['#channi_delay'] = '谗逆',
  [':channi'] = '出牌阶段限一次，你可以交给一名其他角色任意张手牌，然后该角色可以将X张手牌当一张【决斗】使用（X至多为你以此法交给其的牌数）。其因此使用【决斗】造成伤害后，其摸X张牌；其因此使用【决斗】受到伤害后，你弃置所有手牌。',
  ['$channi1'] = '此人心怀叵测，将军当拔剑诛之！',
  ['$channi2'] = '请夫君听妾身之言，勿为小人所误！',
}

channi:addEffect('active', {
  anim_type = "support",
  prompt = "#channi-active",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(channi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select.id ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #effect.cards
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, channi.name, nil, false, player.id)
    room:setPlayerMark(target, channi.name, n)
    local success, data = room:askToUseActiveSkill(target, {
      skill_name = "channi_viewas",
      prompt = "#channi-invoke:"..player.id.."::"..n,
      cancelable = true
    })
    room:setPlayerMark(target, channi.name, 0)
    if success then
      local card = Fk:cloneCard("duel")
      card.skillName = channi.name
      card:addSubcards(data.cards)
      local use = {
        from = target.id,
        tos = table.map(data.targets, function(id) return {id} end),
        card = card,
        extra_data = {channi_data = {player.id, target.id, #data.cards}}
      }
      room:useCard(use)
    end
  end,
})

channi:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and target and not target.dead and data.card and not data.chain and
      table.contains(data.card.skillNames, channi.name) then
      local room = player.room
      local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not card_event then return false end
      local use = card_event.data[1]
      if use.extra_data then
        local channi_data = use.extra_data.channi_data
        if channi_data and channi_data[1] == player.id and channi_data[2] == target.id then
          event:setCostData(self, channi_data[3])
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:notifySkillInvoked(player, channi.name, "drawcard")
      room:doIndicate(player.id, {target.id})
      room:drawCards(target, event:getCostData(self), channi.name)
    else
      room:notifySkillInvoked(player, channi.name, "negative")
      local n = player:getHandcardNum()
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = channi.name,
        cancelable = false
      })
    end
  end
})

return channi
