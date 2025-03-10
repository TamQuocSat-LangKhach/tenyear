local lingkong = fk.CreateSkill {
  name = "lingkong"
}

Fk:loadTranslationTable{
  ['lingkong'] = '灵箜',
  ['@@konghou-inhand'] = '箜篌',
  [':lingkong'] = '锁定技，游戏开始时，你的初始手牌增加“箜篌”标记且不计入手牌上限。每回合你于摸牌阶段外首次获得牌后，将这些牌标记为“箜篌”。',
  ['$lingkong1'] = '箜篌奏晚歌，渔樵有归期。',
  ['$lingkong2'] = '吴宫绿荷惊涟漪，飞燕啄新泥。',
}

-- TriggerSkill部分
lingkong:addEffect({fk.GameStart, fk.AfterCardsMove}, {
  anim_type = "special",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(lingkong.name) then return false end
    local handcards = player:getCardIds(Player.Hand)
    if event == fk.GameStart then
      return #handcards > 0
    elseif event == fk.AfterCardsMove then
      local room = player.room
      if room.current == nil or room.current.phase == Player.Draw or player:getMark("lingkongused-turn") > 0 then return false end
      local cards = {}
      for _, move in ipairs(target) do
        if move.to == player.id and move.toArea == Player.Hand then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if table.contains(handcards, id) then
              table.insert(cards, id)
            end
          end
        end
      end
      cards = U.moveCardsHoldingAreaCheck(player.room, cards)
      if #cards > 0 then
        event:setCostData(self, cards)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if event == fk.GameStart then
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        room:setCardMark(Fk:getCardById(id), "@@konghou-inhand", 1)
      end
    elseif event == fk.AfterCardsMove then
      room:setPlayerMark(player, "lingkongused-turn", 1)
      for _, id in ipairs(event:getCostData(self)) do
        room:setCardMark(Fk:getCardById(id), "@@konghou-inhand", 1)
      end
    end
  end,
  on_lose = function(self, player)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      room:setCardMark(Fk:getCardById(id), "@@konghou-inhand", 0)
    end
  end,
})

-- MaxCardsSkill部分
lingkong:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return card:getMark("@@konghou-inhand") > 0
  end,
})

return lingkong
