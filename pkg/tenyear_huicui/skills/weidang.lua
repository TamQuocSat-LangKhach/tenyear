local weidang = fk.CreateSkill {
  name = "weidang",
}

Fk:loadTranslationTable{
  ["weidang"] = "伪谠",
  [":weidang"] = "其他角色的结束阶段，你可以将一张牌名字数为X的牌置于牌堆底，然后获得牌堆中一张牌名字数为X的牌（X为本回合没有进入过"..
  "弃牌堆的花色数），能使用则使用之。",

  ["#weidang-invoke"] = "伪谠：你可以将一张字数为%arg的牌置于牌堆底，获得一张字数相同的牌并使用",
  ["#weidang-use"] = "伪谠：请使用%arg",

  ["$weidang1"] = "臣等忠耿之言，绝无藏私之意。",
  ["$weidang2"] = "假谠言之术，行利己之实。",
}

weidang:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(weidang.name) and target ~= player and target.phase == Player.Finish and not player:isNude() then
      local suits = {1, 2, 3, 4}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.removeOne(suits, Fk:getCardById(info.cardId).suit)
            end
          end
        end
        return #suits == 0
      end, Player.HistoryTurn)
      if #suits > 0 then
        event:setCostData(self, {choice = #suits})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = event:getCostData(self).choice
    local cards = table.filter(player:getCardIds("he"), function(id)
      return Fk:translate(Fk:getCardById(id).trueName, "zh_CN"):len() == n
    end)
    cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = weidang.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#weidang-invoke:::"..n,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards, choice = n})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:moveCards({
      ids = event:getCostData(self).cards,
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = weidang.name,
      drawPilePosition = -1,
      proposer = player,
    })
    if player.dead then return end
    local cards = table.filter(room.draw_pile, function(id)
      return Fk:translate(Fk:getCardById(id).trueName, "zh_CN"):len() == event:getCostData(self).choice
    end)
    if #cards == 0 then return end
    local id = table.random(cards)
    room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonJustMove, weidang.name, nil, false, player)
    local card = Fk:getCardById(id)
    if not player.dead and table.contains(player:getCardIds("h"), id) and
      player:canUse(card, {bypass_times = true}) then
      room:askToUseRealCard(player, {
        pattern = {id},
        skill_name = weidang.name,
        prompt = "#weidang-use:::"..card:toLogString(),
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
