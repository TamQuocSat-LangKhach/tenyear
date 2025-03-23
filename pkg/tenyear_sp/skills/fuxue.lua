local fuxue = fk.CreateSkill {
  name = "fuxue",
}

Fk:loadTranslationTable{
  ["fuxue"] = "复学",
  [":fuxue"] = "准备阶段，你可以从弃牌堆中获得至多X张不因使用而进入弃牌堆的牌。结束阶段，若你手中没有以此法获得的牌，你摸X张牌。（X为你的体力值）",

  ["@@fuxue-inhand-turn"] = "复学",
  ["#fuxue-invoke"] = "复学：你可以获得弃牌堆中至多%arg张不因使用而进入弃牌堆的牌",
  ["#fuxue-choose"] = "复学：从弃牌堆中挑选至多%arg张卡牌获得",

  ["$fuxue1"] = "普天之大，唯此处可安书桌。",
  ["$fuxue2"] = "书中自有风月，何故东奔西顾？",
}

local function searchFuxueCards(room, findOne)
  if #room.discard_pile == 0 then return {} end
  local ids = {}
  local discard_pile = table.simpleClone(room.discard_pile)
  room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
    for _, move in ipairs(e.data) do
      for _, info in ipairs(move.moveInfo) do
        local id = info.cardId
        if table.removeOne(discard_pile, id) then
          if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
            table.insertIfNeed(ids, id)
            if findOne then
              return ids
            end
          end
        end
      end
    end
    if #discard_pile == 0 then return true end
  end, 0)
  return ids
end

fuxue:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fuxue.name) then
      if player.phase == Player.Start then
        return #searchFuxueCards(player.room, true) > 0
      elseif player.phase == Player.Finish then
        return not table.find(player:getCardIds("h"), function(id)
          return Fk:getCardById(id):getMark("@@fuxue-inhand-turn") > 0
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Start then
      return player.room:askToSkillInvoke(player, {
        skill_name = fuxue.name,
        prompt = "#fuxue-invoke:::"..player.hp,
      })
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if player.phase == Player.Start then
      local room = player.room
      local cards = searchFuxueCards(room)
      if #cards == 0 then return false end
      table.sort(cards, function (a, b)
        local cardA, cardB = Fk:getCardById(a), Fk:getCardById(b)
        if cardA.type == cardB.type then
          if cardA.sub_type == cardB.sub_type then
            if cardA.name == cardB.name then
              return a > b
            else
              return cardA.name > cardB.name
            end
          else
            return cardA.sub_type < cardB.sub_type
          end
        else
          return cardA.type < cardB.type
        end
      end)
      local get = room:askToChooseCards(player, {
        target = player,
        min = 1,
        max = player.hp,
        flag = { card_data = {{ "pile_discard", cards }} },
        skill_name = fuxue.name,
        prompt = "#fuxue-choose:::"..player.hp,
      })
      room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, fuxue.name, nil, false, player, "@@fuxue-inhand-turn")
    else
      player:drawCards(player.hp, fuxue.name)
    end
  end,
})

return fuxue
