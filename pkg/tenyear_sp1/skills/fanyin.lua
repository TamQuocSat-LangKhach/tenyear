local fanyin = fk.CreateSkill {
  name = "fanyin"
}

Fk:loadTranslationTable{
  ['fanyin'] = '泛音',
  ['#fanyin-ask'] = '泛音：使用%arg，或点取消则令你本回合使用的下一张牌可多选目标',
  ['@fanyin-turn'] = '泛音',
  ['#fanyin_delay'] = '泛音',
  ['#fanyin-choose'] = '泛音：你可以为%arg额外指定至多%arg2个目标',
  [':fanyin'] = '出牌阶段开始时，你可以亮出牌堆中点数最小的一张牌并选择一项：1.使用之（无距离限制）；2.令你本回合使用的下一张牌可以多选择一个目标。然后亮出牌堆中点数翻倍的一张牌并重复此流程。',
  ['$fanyin1'] = '此音可协，此律可振。',
  ['$fanyin2'] = '玄妙殊巧，可谓绝技。',
}

fanyin:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(fanyin.name) and player.phase == Player.PhasePlay
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local x, y = 13, 0
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      y = Fk:getCardById(id).number
      if y < x then
        x = y
        cards = {}
      end
      if x == y then
        table.insert(cards, id)
      end
    end
    if #cards == 0 then return false end
    cards = table.random(cards, 1)
    while true do
      room:moveCards({
        ids = cards,
        toArea = Card.Processing,
        skillName = fanyin.name,
        proposer = player.id,
        moveReason = fk.ReasonJustMove,
      })
      if not room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = fanyin.name,
        prompt = "#fanyin-ask:::"..Fk:getCardById(cards[1]):toLogString(),
        expand_pile = cards,
        bypass_distances = true,
      }) then
        room:moveCards({
          ids = cards,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = fanyin.name,
        })
        room:addPlayerMark(player, "@fanyin-turn")
      end
      if player.dead then return end
      x = 2*x
      if x > 13 then return end
      cards = room:getCardsFromPileByRule(".|" .. x)
      if #cards == 0 then return end
    end
  end,
})

fanyin:addEffect(fk.AfterCardTargetDeclared, {
  name = "#fanyin_delay",
  mute = true,
  can_trigger = function(self, event, target, player)
    return not player.dead and player == target and player:getMark("@fanyin-turn") > 0 and
      (event.card:isCommonTrick() or event.card.type == Card.TypeBasic)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("@fanyin-turn")
    room:setPlayerMark(player, "@fanyin-turn", 0)
    local targets = room:getUseExtraTargets(data)
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = x,
      prompt = "#fanyin-choose:::"..data.card:toLogString() .. ":" .. tostring(x),
      skill_name = fanyin.name,
    })
    if #tos > 0 then
      table.forEach(tos, function (id)
        table.insert(data.tos, {id})
      end)
    end
  end,
})

return fanyin
