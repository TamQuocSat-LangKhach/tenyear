local zhizhe = fk.CreateSkill {
  name = "zhizhe"
}

Fk:loadTranslationTable{
  ['zhizhe'] = '智哲',
  ['#zhizhe-active'] = '发动 智哲，选择一张手牌（衍生牌除外），获得一张此牌的复制',
  ['#zhizhe_delay'] = '智哲',
  ['@@zhizhe-inhand'] = '智哲',
  [':zhizhe'] = '限定技，出牌阶段，你可以复制一张手牌（衍生牌除外）。此牌因你使用或打出而进入弃牌堆后，你获得且本回合不能再使用或打出之。',
  ['$zhizhe1'] = '轻舟载浊酒，此去，我欲借箭十万。',
  ['$zhizhe2'] = '主公有多大胆略，亮便有多少谋略。',
}

-- 主动技能
zhizhe:addEffect('active', {
  name = "zhizhe",
  prompt = "#zhizhe-active",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zhizhe.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
      and not Fk:getCardById(to_select).is_derived and to_select > 0
  end,
  on_use = function(self, room, effect)
    local c = Fk:getCardById(effect.cards[1], true)
    local toGain = room:printCard(c.name, c.suit, c.number)
    room:moveCards({
      ids = {toGain.id},
      to = effect.from,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = effect.from,
      skillName = zhizhe.name,
      moveVisible = false,
    })
  end
})

-- 触发技能
zhizhe:addEffect(fk.AfterCardsMove, {
  name = "#zhizhe_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local mark = player:getTableMark("zhizhe")
    if #mark == 0 then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    if parent_event and (parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard) then
      local parent_data = parent_event.data[1]
      if parent_data.from == player.id then
        local card_ids = room:getSubcardsByRule(parent_data.card)
        local to_get = {}
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if info.fromArea == Card.Processing and room:getCardArea(id) == Card.DiscardPile and
                table.contains(card_ids, id) and table.contains(mark, id) then
                table.insertIfNeed(to_get, id)
              end
            end
          end
        end
        if #to_get > 0 then
          event:setCostData(self, to_get)
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, zhizhe.name)
    player:broadcastSkillInvoke(zhizhe.name)
    room:obtainCard(player, event:getCostData(self), true, fk.ReasonJustMove, player.id, "zhizhe")
  end,
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local marked = player:getTableMark("zhizhe")
    local marked2 = player:getTableMark("zhizhe-turn")
    marked2 = table.filter(marked2, function (id)
      return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player
    end)
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == zhizhe.name then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            if info.fromArea == Card.Void then
              table.insertIfNeed(marked, id)
            else
              table.insert(marked2, id)
            end
            room:setCardMark(Fk:getCardById(id), "@@zhizhe-inhand", 1)
          end
        end
      elseif move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          table.removeOne(marked, id)
        end
      end
    end
    room:setPlayerMark(player, "zhizhe", marked)
    room:setPlayerMark(player, "zhizhe-turn", marked2)
  end,
})

-- 禁用技能
zhizhe:addEffect('prohibit', {
  name = "#zhizhe_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getTableMark("zhizhe-turn")
    if #mark == 0 then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("zhizhe-turn")
    if #mark == 0 then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
})

return zhizhe
