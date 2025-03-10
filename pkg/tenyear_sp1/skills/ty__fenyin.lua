local ty__fenyin = fk.CreateSkill {
  name = "ty__fenyin"
}

Fk:loadTranslationTable{
  ['ty__fenyin'] = '奋音',
  ['@fenyin_suits-turn'] = '奋音',
  [':ty__fenyin'] = '锁定技，你的回合内，每当有一种花色的牌进入弃牌堆后（每回合每种花色各限一次），你摸一张牌。',
  ['$ty__fenyin1'] = '斗志高歌，士气昂扬！',
  ['$ty__fenyin2'] = '抗音而歌，左右应之！',
}

ty__fenyin:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty__fenyin.name) and player.phase ~= Player.NotActive then
      local mark = player:getTableMark("@fenyin_suits-turn")
      if #mark > 3 then return false end
      local suits = {}
      local suit = ""
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            suit = Fk:getCardById(info.cardId):getSuitString(true)
            if suit ~= "log_nosuit" and not table.contains(mark, suit) then
              table.insertIfNeed(suits, suit)
            end
          end
        end
      end
      if #suits > 0 then
        event:setCostData(self, suits)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local mark = player:getTableMark("@fenyin_suits-turn")
    table.insertTable(mark, event:getCostData(self))
    player.room:setPlayerMark(player, "@fenyin_suits-turn", mark)
    player:drawCards(#event:getCostData(self), ty__fenyin.name)
  end,
})

return ty__fenyin
