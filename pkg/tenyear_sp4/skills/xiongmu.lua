local xiongmu = fk.CreateSkill {
  name = "xiongmu"
}

Fk:loadTranslationTable{
  ['xiongmu'] = '雄幕',
  ['#xiongmu-draw'] = '雄幕：是否将手牌补至体力上限（摸%arg张牌）',
  ['#xiongmu-cards'] = '雄幕：你可将任意张牌随机置入牌堆，然后获得等量张点数为8的牌',
  ['@@xiongmu-inhand-round'] = '雄幕',
  [':xiongmu'] = '每轮开始时，你可以将手牌摸至体力上限，然后将任意张牌随机置入牌堆，从牌堆或弃牌堆中获得等量的点数为8的牌，这些牌此轮内不计入你的手牌上限。当你每回合受到第一次伤害时，若你的手牌数小于等于体力值，此伤害-1。',
  ['$xiongmu1'] = '步步为营者，定无后顾之虞。',
  ['$xiongmu2'] = '明公彀中藏龙卧虎，放之海内皆可称贤。',
}

xiongmu:addEffect(fk.RoundStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) then
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(xiongmu.name)
    room:notifySkillInvoked(player, xiongmu.name, "drawcard")
    local x = player.maxHp - player:getHandcardNum()
    if x > 0 and room:askToSkillInvoke(player, {skill_name = xiongmu.name, prompt = "#xiongmu-draw:::" .. tostring(x)}) then
      room:drawCards(player, x, xiongmu.name)
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
        from = player.id,
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
      player.room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = xiongmu.name,
        moveMark = "@@xiongmu-inhand-round",
      })
    end
  end,
})

xiongmu:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xiongmu.name) then
      return player == target and player:getHandcardNum() <= player.hp and player:getMark("xiongmu_defensive-turn") == 0 and
        #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local damage = e.data[5]
          return damage and damage.to == player
        end, Player.HistoryTurn) == 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(xiongmu.name)
    room:notifySkillInvoked(player, xiongmu.name, "defensive")
    room:setPlayerMark(player, "xiongmu_defensive-turn", 1)
    data.damage = data.damage - 1
  end,
})

local xiongmu_maxcards = fk.CreateMaxCardsSkill{
  name = "#xiongmu_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@xiongmu-inhand-round") > 0
  end,
}

return xiongmu
