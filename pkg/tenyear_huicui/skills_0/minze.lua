local minze = fk.CreateSkill {
  name = "minze"
}

Fk:loadTranslationTable{
  ['minze'] = '悯泽',
  ['@$minze-turn'] = '悯泽',
  [':minze'] = '出牌阶段每名角色限一次，你可以将至多两张牌名不同的牌交给一名手牌数小于你的角色。结束阶段，你将手牌补至X张（X为本回合你因此技能失去牌的牌名数，至多为5）。',
  ['$minze1'] = '百姓千载皆苦，勿以苛政待之。',
  ['$minze2'] = '黎庶待哺，人主当施恩德泽。',
}

minze:addEffect('active', {
  anim_type = "support",
  min_card_num = 1,
  max_card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:getCardById(to_select).trueName ~= Fk:getCardById(selected[1]).trueName
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and player:getHandcardNum() > target:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = player:getTableMark("@$minze-turn")
    for _, id in ipairs(effect.cards) do
      table.insertIfNeed(mark, Fk:getCardById(id).trueName)
    end
    room:setPlayerMark(player, "@$minze-turn", mark)
    room:setPlayerMark(target, "minze-phase", 1)
    room:obtainCard(target, effect.cards, false, fk.ReasonGive, player.id)
  end,
})

minze:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(minze.name) and player.phase == Player.Finish and
      player:getMark("@$minze-turn") ~= 0 and player:getHandcardNum() < math.min(#player:getMark("@$minze-turn"), 5)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(minze.name)
    room:notifySkillInvoked(player, minze.name, "drawcard")
    player:drawCards(math.min(#player:getMark("@$minze-turn"), 5) - player:getHandcardNum(), minze.name)
  end,
})

return minze
