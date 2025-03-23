local xialei = fk.CreateSkill {
  name = "xialei"
}

Fk:loadTranslationTable{
  ['xialei'] = '霞泪',
  ['xialei_top'] = '将剩余牌置于牌堆顶',
  ['xialei_bottom'] = '将剩余牌置于牌堆底',
  ['#xialei-chooose'] = '霞泪：选择一张卡牌获得',
  [':xialei'] = '当你的红色牌进入弃牌堆后，你可观看牌堆顶的三张牌，然后你获得一张并可将其他牌置于牌堆底，你本回合观看牌数-1。',
  ['$xialei1'] = '采霞揾晶泪，沾我青衫湿。',
  ['$xialei2'] = '登车入宫墙，垂泪凝如瑙。',
}

xialei:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(xialei.name) or player:getMark("xialei-turn") > 2 then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    local card_ids = {}
    if parent_event ~= nil then
      if parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard then
        local parent_data = parent_event.data[1]
        if parent_data.from == player.id then
          card_ids = room:getSubcardsByRule(parent_data.card)
        end
      elseif parent_event.event == GameEvent.Pindian then
        local pindianData = parent_event.data[1]
        if pindianData.from == player then
          card_ids = room:getSubcardsByRule(pindianData.fromCard)
        else
          for toId, result in pairs(pindianData.results) do
            if player.id == toId then
              card_ids = room:getSubcardsByRule(result.toCard)
              break
            end
          end
        end
      end
    end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        elseif #card_ids > 0 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.Processing and table.contains(card_ids, info.cardId) and
              Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = U.turnOverCardsFromDrawPile(player, 3 - player:getMark("xialei-turn"), xialei.name, false)
    if #ids == 1 then
      room:obtainCard(player, ids, false, fk.ReasonJustMove, player.id, xialei.name)
    else
      local to_return = {}
      local choice = room:askToChoices(player, {
        choices = {"xialei_top", "xialei_bottom"},
        skill_name = xialei.name,
        prompt = "#xialei-chooose"
      })
      for _, id in ipairs(ids) do
        if not table.contains(to_return, id) then
          to_return[#to_return + 1] = id
        end
      end
      room:obtainCard(player, to_return, false, fk.ReasonJustMove, player.id, xialei.name)
      U.returnCardsToDrawPile(player, ids, xialei.name, choice == "xialei_top", false)
    end
    room:addPlayerMark(player, "xialei-turn", 1)
  end,
})

xialei:addEffect('on_lose', function(skill, player)
  player.room:setPlayerMark(player, "xialei-turn", 0)
end)

return xialei
