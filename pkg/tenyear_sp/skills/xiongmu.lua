local xiongmu = fk.CreateSkill {
  name = "xiongmu",
}

Fk:loadTranslationTable{
  ["xiongmu"] = "雄幕",
  [":xiongmu"] = "每轮开始时，你可以将手牌摸至体力上限，然后将任意张牌随机置入牌堆，从牌堆或弃牌堆中获得等量的点数为8的牌，"..
  "这些牌此轮内不计入你的手牌上限。当你每回合受到第一次伤害时，若你的手牌数不大于体力值，此伤害-1。",

  ["#xiongmu-draw"] = "雄幕：是否将手牌补至体力上限（摸%arg张牌）",
  ["#xiongmu-cards"] = "雄幕：你可以将任意张牌随机置入牌堆，获得等量点数为8的牌",
  ["@@xiongmu-inhand-round"] = "雄幕",

  ["$xiongmu1"] = "步步为营者，定无后顾之虞。",
  ["$xiongmu2"] = "明公彀中藏龙卧虎，放之海内皆可称贤。",
}

xiongmu:addEffect(fk.RoundStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiongmu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player.maxHp - player:getHandcardNum()
    if x > 0 and room:askToSkillInvoke(player, {
      skill_name = xiongmu.name,
      prompt = "#xiongmu-draw:::"..x,
    }) then
      player:drawCards(x, xiongmu.name)
      if player.dead then return false end
    end
    if player:isNude() then return false end
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 998,
      include_equip = true,
      skill_name = xiongmu.name,
      prompt = "#xiongmu-cards"
    })
    x = #cards
    if x == 0 then return false end
    table.shuffle(cards)
    local positions = {}
    local y = #room.draw_pile
    for _ = 1, x, 1 do
      table.insert(positions, math.random(y+1))
    end
    table.sort(positions, function (a, b) return a > b end)
    local moveInfos = {}
    for i = 1, x, 1 do
      table.insert(moveInfos, {
        ids = {cards[i]},
        from = player,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = xiongmu.name,
        drawPilePosition = positions[i],
      })
    end
    room:moveCards(table.unpack(moveInfos))
    if player.dead then return false end
    cards = room:getCardsFromPileByRule(".|8", x)
    if x > #cards then
      table.insertTable(cards, room:getCardsFromPileByRule(".|8", x - #cards, "discardPile"))
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, xiongmu.name, nil, false, player, "@@xiongmu-inhand-round")
    end
  end,
})

xiongmu:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiongmu.name) and
      player:getHandcardNum() <= player.hp and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        return e.data.reason == "damage" and e.data.who == player
      end, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
  end,
})

xiongmu:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@xiongmu-inhand-round") > 0
  end,
})

return xiongmu
