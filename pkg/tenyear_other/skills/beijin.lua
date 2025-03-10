local beijin = fk.CreateSkill {
  name = "beijin"
}

Fk:loadTranslationTable{
  ['beijin'] = '北进',
  ['#beijin'] = '北进：摸一张牌，若你手牌中已有“北进”牌或使用下一张牌若不为“北进”牌，则失去体力',
  ['@@beijin-inhand-turn'] = '北进',
  ['#beijin_delay'] = '北进',
  [':beijin'] = '出牌阶段，你可以摸一张牌且此牌无次数限制。若你本回合使用的下一张牌不包含以此法摸的牌，或你发动此技能时手牌中有以此法摸的牌，你失去1点体力。',
}

beijin:addEffect('active', {
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = "#beijin",
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "beijin-turn", 1)
    local yes = table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@beijin-inhand-turn") > 0
    end)
    player:drawCards(1, beijin.name, "top", "@@beijin-inhand-turn")
    if yes and not player.dead then
      room:loseHp(player, 1, beijin.name)
    end
  end,
})

beijin:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@beijin-inhand-turn") > 0
  end,
})

beijin:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.beijin and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, beijin.name)
  end,
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("beijin-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "beijin-turn", 0)
    if not table.find(Card:getIdList(data.card), function (id)
      return Fk:getCardById(id):getMark("@@beijin-inhand-turn") > 0
    end) then
      data.extra_data = data.extra_data or {}
      data.extra_data.beijin = true
    else
      data.extraUse = true
    end
  end,
})

return beijin
