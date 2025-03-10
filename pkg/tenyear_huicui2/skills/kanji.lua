local kanji = fk.CreateSkill {
  name = "kanji"
}

Fk:loadTranslationTable{
  ['kanji'] = '勘集',
  ['#kanji-active'] = '发动 勘集，展示所有手牌%arg',
  ['@@kanji-turn'] = '勘集',
  [':kanji'] = '出牌阶段限两次，你可以展示所有手牌，若花色均不同，你摸两张牌，然后若因此使手牌包含四种花色，则你跳过本回合的弃牌阶段。',
  ['$kanji1'] = '览文库全书，筑文心文胆。',
  ['$kanji2'] = '世间学问，皆载韦编之上。',
}

kanji:addEffect('active', {
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = function(self, player)
    local suits = {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        if table.contains(suits, suit) then
          return "#kanji-active"
        else
          table.insert(suits, suit)
        end
      end
    end
    return "#kanji-active:::kanji_draw"
  end,
  times = function(self, player)
    return player.phase == Player.Play and 2 - player:usedSkillTimes(kanji.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(kanji.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local suits = {}
    for _, id in ipairs(cards) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        if table.contains(suits, suit) then
          return
        else
          table.insert(suits, suit)
        end
      end
    end
    local suits1 = #suits
    player:drawCards(2, kanji.name)
    if suits1 == 4 then return end
    suits = {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    if #suits == 4 then
      room:setPlayerMark(player, "@@kanji-turn", 1)
      player:skip(Player.Discard)
    end
  end,
})

return kanji
