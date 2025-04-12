local bingyi = fk.CreateSkill {
  name = "ty_ex__bingyi",
}

Fk:loadTranslationTable{
  ["ty_ex__bingyi"] = "秉壹",
  [":ty_ex__bingyi"] = "结束阶段，你可以展示所有手牌，若均为同一颜色，你可以令至多X名角色各摸一张牌（X为你的手牌数）；若点数也相同，"..
  "你摸一张牌。",

  ["#ty_ex__bingyi-choose"] = "秉壹：你可以令至多%arg名角色各摸一张牌",

  ["$ty_ex__bingyi1"] = "秉持心性，心口如一。",
  ["$ty_ex__bingyi2"] = "秉忠职守，一生不事二主。",
}

bingyi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bingyi.name) and player.phase == Player.Finish and
      not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("h")
    player:showCards(cards)
    if player.dead then return end
    if table.every(cards, function (id)
      return Fk:getCardById(id).color == Fk:getCardById(cards[1]).color
    end) then
      if Fk:getCardById(cards[1]).color == Card.NoColor then return end
      local tos = room:askToChoosePlayers(player, {
        skill_name = bingyi.name,
        min_num = 1,
        max_num = #cards,
        targets = room.alive_players,
        prompt = "#ty_ex__bingyi-choose:::"..#cards,
      })
      if #tos > 0 then
        room:sortByAction(tos)
        for _, p in ipairs(tos) do
          if not p.dead then
            p:drawCards(1, bingyi.name)
          end
        end
      end
      if not player.dead and table.every(cards, function(id)
        return Fk:getCardById(id).number == Fk:getCardById(cards[1]).number
      end) then
        player:drawCards(1, bingyi.name)
      end
    end
  end,
})

return bingyi
