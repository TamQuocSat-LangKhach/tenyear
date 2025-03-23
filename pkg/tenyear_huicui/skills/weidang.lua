local weidang = fk.CreateSkill {
  name = "weidang"
}

Fk:loadTranslationTable{
  ['weidang'] = '伪谠',
  ['#weidang_active'] = '伪谠',
  ['#weidang-invoke'] = '伪谠：可将名字数为 %arg 的牌置于牌堆底，从获得一张字数相同的牌并使用',
  ['#weidang-use'] = '伪谠：请使用%arg',
  [':weidang'] = '其他角色的结束阶段，你可以将一张牌名字数为X的牌置于牌堆底，然后获得牌堆中一张牌名字数为X的牌（X为本回合没有进入过弃牌堆的花色数），能使用则使用之。',
  ['$weidang1'] = '臣等忠耿之言，绝无藏私之意。',
  ['$weidang2'] = '假谠言之术，行利己之实。',
}

weidang:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(weidang.name) and target ~= player and target.phase == Player.Finish and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local suits = {1,2,3,4}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            local suit = Fk:getCardById(info.cardId).suit
            table.removeOne(suits, suit)
          end
        end
      end
      return #suits == 0
    end, Player.HistoryTurn)
    local n = #suits
    if n > 0 then
      local _,dat = room:askToUseActiveSkill(player, {
        skill_name = "#weidang_active",
        prompt = "#weidang-invoke:::"..n,
        cancelable = true,
        extra_data = {weidang_num = n},
      })
      if dat then
        event:setCostData(self, dat.cards)
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:moveCards({
      ids = event:getCostData(self),
      from = player.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = weidang.name,
      drawPilePosition = -1,
      proposer = player.id,
    })
    if player.dead then return end
    local num = Fk:translate(Fk:getCardById(event:getCostData(self)[1]).trueName, "zh_CN"):len()
    local cards = table.filter(room.draw_pile, function(id)
      return Fk:translate(Fk:getCardById(id).trueName, "zh_CN"):len() == num
    end)
    if #cards == 0 then return end
    local id = table.random(cards)
    room:moveCards({
      ids = {id},
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = weidang.name,
    })
    if table.contains(player:getCardIds("h"), id) then
      room:askToUseRealCard(player, {
        pattern = {id},
        skill_name = weidang.name,
        prompt = "#weidang-use:::"..Fk:getCardById(id):toLogString(),
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
        cancelable = false,
      })
    end
  end,
})

return weidang
