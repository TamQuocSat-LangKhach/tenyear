local chenlue = fk.CreateSkill {
  name = "chenlue"
}

Fk:loadTranslationTable{
  ['chenlue'] = '沉略',
  ['#chenlue-active'] = '发动 沉略，获得所有被标记的“死士”牌（回合结束后移出游戏）',
  ['sanshi'] = '散士',
  ['#chenlue_delay'] = '沉略',
  ['#chenlue'] = '沉略',
  [':chenlue'] = '限定技，出牌阶段，你可以从牌堆、弃牌堆、场上或其他角色的手牌中获得所有“死士”牌，此阶段结束时，将这些牌移出游戏直到你死亡。',
  ['$chenlue1'] = '怀泰山之重，必立以千仞。',
  ['$chenlue2'] = '万世之勋待取，此乃亮剑之时。',
}

-- 主动技能部分
chenlue:addEffect('active', {
  anim_type = "drawcard",
  prompt = "#chenlue-active",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(chenlue.name, Player.HistoryGame) == 0 and #player:getTableMark("sanshi") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local areas = {Card.PlayerEquip, Card.PlayerJudge, Card.DrawPile, Card.DiscardPile}
    local cards = table.filter(player:getTableMark("sanshi"), function (id)
      local area = room:getCardArea(id)
      return table.contains(areas, area) or (area == Card.PlayerHand and room:getCardOwner(id) ~= player)
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, chenlue.name, nil, true, player.id)
      room:setPlayerMark(player, "chenlue-phase", cards)
    end
  end,
})

-- 触发技能部分
chenlue:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if player.dead or player:getMark("chenlue-phase") == 0 then return false end
    local areas = {Card.DrawPile, Card.DiscardPile, Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge}
    local room = player.room
    local cards = table.filter(player:getTableMark("chenlue-phase"), function (id)
      return table.contains(areas, room:getCardArea(id))
    end)
    if #cards > 0 then
      event:setCostData(self, cards)
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local cost_data = event:getCostData(self)
    player:addToPile("#chenlue", table.simpleClone(cost_data), true, chenlue.name)
  end,
})

return chenlue
