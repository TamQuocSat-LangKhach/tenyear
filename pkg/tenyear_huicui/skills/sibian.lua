local sibian = fk.CreateSkill {
  name = "sibian",
}

Fk:loadTranslationTable{
  ["sibian"] = "思辩",
  [":sibian"] = "摸牌阶段，你可以放弃摸牌，改为亮出牌堆顶的4张牌，你获得其中所有点数最大和最小的牌，然后你可以将剩余的牌交给一名手牌数最少的角色。",

  ["#sibian-choose"] = "思辩：你可以将剩余的牌交给一名手牌数最少的角色",

  ["$sibian1"] = "才藻俊茂，辨思如涌。",
  ["$sibian2"] = "弘雅之素，英秀之德。",
}

sibian:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sibian.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    local cards = room:getNCards(4)
    room:turnOverCardsFromDrawPile(player, cards, sibian.name)
    local min, max = 13, 1
    for _, id in ipairs(cards) do
      local num = Fk:getCardById(id).number
      if num < min then
        min = num
      end
      if num > max then
        max = num
      end
    end
    local get = {}
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).number == min or Fk:getCardById(cards[i]).number == max then
        table.insert(get, cards[i])
        table.remove(cards, i)
      end
    end
    room:delay(1000)
    room:obtainCard(player, get, false, fk.ReasonJustMove, player, sibian.name)
    if #cards > 0 and not player.dead then
      local targets = table.filter(room.alive_players, function (p)
        return table.every(room.alive_players, function (q)
          return q:getHandcardNum() >= p:getHandcardNum()
        end)
      end)
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#sibian-choose",
        skill_name = sibian.name,
        cancelable = true,
      })
      if #to > 0 then
        room:obtainCard(to[1], cards, false, fk.ReasonGive, player, sibian.name)
      else
      end
    end
    room:cleanProcessingArea(cards)
  end,
})

return sibian
