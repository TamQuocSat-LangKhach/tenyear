local xialei = fk.CreateSkill {
  name = "xialei",
}

Fk:loadTranslationTable{
  ["xialei"] = "霞泪",
  [":xialei"] = "当你的红色牌进入弃牌堆后，你可以观看牌堆顶三张牌，获得其中一张并可以将其余牌置于牌堆底，然后你本回合观看牌数-1。",

  ["xialei_top"] = "将剩余牌置于牌堆顶",
  ["xialei_bottom"] = "将剩余牌置于牌堆底",
  ["#xialei-prey"] = "霞泪：获得其中一张牌",

  ["$xialei1"] = "采霞揾晶泪，沾我青衫湿。",
  ["$xialei2"] = "登车入宫墙，垂泪凝如瑙。",
}

xialei:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xialei.name) and player:getMark("xialei-turn") < 3 then
      local room = player.room
      local move_event = room.logic:getCurrentEvent()
      local use_event = move_event.parent
      local card_ids = {}
      if use_event ~= nil then
        if use_event.event == GameEvent.UseCard or use_event.event == GameEvent.RespondCard then
          local use = use_event.data
          if use.from == player then
            card_ids = room:getSubcardsByRule(use.card)
          end
        elseif use_event.event == GameEvent.Pindian then
          local pindianData = use_event.data
          if pindianData.from == player then
            card_ids = room:getSubcardsByRule(pindianData.fromCard)
          else
            for to, result in pairs(pindianData.results) do
              if to == player then
                card_ids = room:getSubcardsByRule(result.toCard)
                break
              end
            end
          end
        end
      end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.from == player then
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
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3 - player:getMark("xialei-turn"))
    room:turnOverCardsFromDrawPile(player, ids, xialei.name, false)
    if #ids == 1 then
      room:obtainCard(player, ids, false, fk.ReasonJustMove, player, xialei.name)
    else
      local card = room:askToChooseCard(player, {
        target = player,
        flag = { card_data = {{ "Top", ids }} },
        skill_name = xialei.name,
        prompt = "#xialei-prey",
      })
      room:obtainCard(player, card, false, fk.ReasonJustMove, player, xialei.name)
      if player.dead then
        room:cleanProcessingArea(ids)
        return
      end
      table.removeOne(ids, card)
      local choice = room:askToChoice(player, {
        choices = { "xialei_top", "xialei_bottom" },
        skill_name = xialei.name,
      })
      room:returnCardsToDrawPile(player, ids, xialei.name, choice == "xialei_top" and "top" or "bottom", false)
    end
    room:addPlayerMark(player, "xialei-turn", 1)
  end,
})

xialei:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "xialei-turn", 0)
end)

return xialei
