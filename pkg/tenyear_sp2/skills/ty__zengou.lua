local ty__zengou = fk.CreateSkill {
  name = "ty__zengou"
}

Fk:loadTranslationTable{
  ['ty__zengou'] = '谮构',
  ['#ty__zengou'] = '谮构：交给一名角色至多%arg张牌并摸等量牌，其下次体力增加或使用牌后失去体力',
  ['@@ty__zengou'] = '谮构',
  ['@@ty__zengou-inhand'] = '谮构',
  [':ty__zengou'] = '出牌阶段限一次，你可以交给一名其他角色至多你体力上限张牌并摸等量的牌，若如此做，其下次体力值增加或使用牌后展示所有手牌，每有一张“谮构”牌，其失去1点体力。',
  ['$ty__zengou1'] = '既已同床异梦，休怪妾身无情。',
  ['$ty__zengou2'] = '我所恨者，唯夏侯子林一人耳。',
}

ty__zengou:addEffect('active', {
  anim_type = "control",
  min_card_num = 1,
  target_num = 1,
  prompt = function(self, player)
    return "#ty__zengou:::"..player.maxHp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(ty__zengou.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player.maxHp
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = effect.cards
    room:setPlayerMark(target, "@@ty__zengou", 1)
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, ty__zengou.name, nil, false, player.id, "@@ty__zengou-inhand")
    if not player.dead then
      player:drawCards(#cards, ty__zengou.name)
    end
  end,
})

ty__zengou:addEffect(fk.HpChanged + fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("@@ty__zengou") > 0 then
      if event == fk.HpChanged then
        return data.num > 0
      else
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ty__zengou", 0)
    if player:isKongcheng() then return end
    local cards = player:getCardIds("h")
    local n = #table.filter(cards, function(id)
      return Fk:getCardById(id):getMark("@@ty__zengou-inhand") > 0
    end)
    player:showCards(cards)
    if player.dead or n == 0 then return end
    room:loseHp(player, n, "ty__zengou")
  end,
})

return ty__zengou
