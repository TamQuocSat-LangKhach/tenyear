local gaojian = fk.CreateSkill {
  name = "gaojian",
}

Fk:loadTranslationTable{
  ["gaojian"] = "告谏",
  [":gaojian"] = "当你于出牌阶段使用锦囊牌结算完毕进入弃牌堆时，你可以选择一名其他角色，其依次展示牌堆顶的牌直到出现锦囊牌（至多五张），"..
  "然后其选择一项：1.使用此牌；2.将任意张手牌与等量展示牌交换。然后将剩余牌置于牌堆顶。",

  ["#gaojian-choose"] = "告谏：选择一名角色，其展示牌堆顶牌，使用其中的锦囊牌或用手牌交换",
  ["#gaojian-use"] = "告谏：使用%arg，或点“取消”将任意张手牌与等量展示牌交换",
  ["#gaojian-exchange"] = "告谏：将任意张手牌与等量展示牌交换",

  ["$gaojian1"] = "江东不乏能人，主公不可小觑。",
  ["$gaojian2"] = "狮子搏兔，亦需尽其全力。",
}

gaojian:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gaojian.name) and
      data.card:isCommonTrick() and player.phase == Player.Play and
      (not data.card:isVirtual() or data.card.subcards) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#gaojian-choose",
      skill_name = gaojian.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = {}
    for i = 1, 5, 1 do
      local card = room:getNCards(1)
      room:turnOverCardsFromDrawPile(to, card, gaojian.name)
      table.insert(cards, card[1])
      if Fk:getCardById(card[1]).type == Card.TypeTrick then
        break
      end
    end
    local yes = false
    if Fk:getCardById(cards[#cards]).type == Card.TypeTrick then
      local id = cards[#cards]
      if room:askToUseRealCard(to, {
        pattern = {id},
        skill_name = gaojian.name,
        prompt = "#gaojian-use:::"..Fk:getCardById(id):toLogString(),
        extra_data = {
          bypass_times = true,
          extraUse = true,
          expand_pile = {id},
        },
      }) then
        yes = true
      end
    end
    if not yes then
      local results = room:askToArrangeCards(to, {
        skill_name = gaojian.name,
        card_map = {
          "Top", cards,
          "hand_card", to:getCardIds("h"),
        },
        prompt = "#gaojian-exchange",
      })
      if #results > 0 then
        room:swapCardsWithPile(to, results[1], results[2], gaojian.name, "Top")
      end
    end
    cards = table.filter(cards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #cards > 0 then
      room:returnCardsToDrawPile(to, cards, gaojian.name)
    end
  end,
})

return gaojian
