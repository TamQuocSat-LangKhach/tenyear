local baoshi = fk.CreateSkill {
  name = "baoshi"
}

Fk:loadTranslationTable{
  ['baoshi'] = '暴食',
  ['baoshi_prey'] = '获得这些牌',
  ['baoshi_show'] = '再亮出一张',
  ['#baoshi-choice'] = '暴食：现在总字数为%arg，若超过10则不能获得！',
  [':baoshi'] = '摸牌阶段结束时，你可以亮出牌堆顶的两张牌。若亮出牌的牌名字数之和不大于10（【桃】或【酒】不计入牌名字数统计），你选择一项：1.获得所有亮出的牌；2.再亮出一张。',
}

baoshi:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(baoshi.name) and player.phase == Player.Draw
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(2)
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonJustMove, baoshi.name, nil, true, player.id)
    local n = 0
    for _, id in ipairs(cards) do
      local name = Fk:getCardById(id).trueName
      if not table.contains({"peach", "analeptic"}, name) then
        n = n + Fk:translate(name, "zh_CN"):len()
      end
    end
    if n <= 10 then
      room:setCardEmotion(cards[2], "judgegood")
      room:delay(600)
    end
    while n <= 10 do
      local choice = room:askToChoice(player, {
        choices = {"baoshi_prey", "baoshi_show"},
        skill_name = baoshi.name,
        prompt = "#baoshi-choice:::"..n
      })
      if choice == "baoshi_prey" then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, baoshi.name, nil, true, player.id)
        return
      else
        local id = room:getNCards(1)[1]
        table.insert(cards, id)
        room:moveCardTo(id, Card.Processing, nil, fk.ReasonJustMove, baoshi.name, nil, true, player.id)
        local name = Fk:getCardById(id).trueName
        if not table.contains({"peach", "analeptic"}, name) then
          n = n + Fk:translate(name, "zh_CN"):len()
        end
        if n <= 10 then
          room:setCardEmotion(id, "judgegood")
        else
          room:setCardEmotion(id, "judgebad")
        end
        room:delay(600)
      end
    end
    room:cleanProcessingArea(cards, baoshi.name)
  end,
})

return baoshi
