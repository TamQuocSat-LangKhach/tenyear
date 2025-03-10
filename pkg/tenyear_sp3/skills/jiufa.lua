local jiufa = fk.CreateSkill {
  name = "jiufa"
}

Fk:loadTranslationTable{
  ['jiufa'] = '九伐',
  ['@$jiufa'] = '九伐',
  ['#jiufa-invoke'] = '九伐：是否亮出牌堆顶九张牌，获得重复点数的牌各一张！',
  ['#jiufa'] = '九伐：从亮出的牌中选择并获得其中每个重复点数的牌各一张',
  [':jiufa'] = '当你每累计使用或打出九张不同牌名的牌后，你可以亮出牌堆顶的九张牌，然后若其中有点数相同的牌，你选择并获得其中每个重复点数的牌各一张。',
  ['$jiufa1'] = '九伐中原，以圆先帝遗志。',
  ['$jiufa2'] = '日日砺剑，相报丞相厚恩。',
}

jiufa:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiufa.name) and
      not table.contains(player:getTableMark("@$jiufa"), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(player, "@$jiufa", data.card.trueName)
    if #player:getTableMark("@$jiufa") < 9 or not room:askToSkillInvoke(player, { skill_name = jiufa.name, prompt = "#jiufa-invoke" }) then return false end
    room:setPlayerMark(player, "@$jiufa", 0)
    local card_ids = U.turnOverCardsFromDrawPile(player, 9, jiufa.name)
    local get, throw = {}, {}
    local number_table = {}
    for _ = 1, 13, 1 do
      table.insert(number_table, 0)
    end
    for _, id in ipairs(card_ids) do
      local x = Fk:getCardById(id).number
      number_table[x] = number_table[x] + 1
      if number_table[x] == 2 then
        table.insert(get, id)
      else
        table.insert(throw, id)
      end
    end
    local result = room:askToArrangeCards(player, {
      skill_name = jiufa.name,
      card_map = {card_ids},
      prompt = "#jiufa",
      box_size = 0,
      max_limit = {9, 9},
      min_limit = {0, #get},
      pattern = ".",
      poxi_type = "jiufa",
      default_choice = {throw, get}
    })
    throw = result[1]
    get = result[2]
    if #get > 0 then
      room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, jiufa.name, "", true, player.id)
    end
    room:cleanProcessingArea(card_ids, jiufa.name)
  end,
})

jiufa:addEffect(fk.CardResponding, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiufa.name) and
      not table.contains(player:getTableMark("@$jiufa"), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(player, "@$jiufa", data.card.trueName)
    if #player:getTableMark("@$jiufa") < 9 or not room:askToSkillInvoke(player, { skill_name = jiufa.name, prompt = "#jiufa-invoke" }) then return false end
    room:setPlayerMark(player, "@$jiufa", 0)
    local card_ids = U.turnOverCardsFromDrawPile(player, 9, jiufa.name)
    local get, throw = {}, {}
    local number_table = {}
    for _ = 1, 13, 1 do
      table.insert(number_table, 0)
    end
    for _, id in ipairs(card_ids) do
      local x = Fk:getCardById(id).number
      number_table[x] = number_table[x] + 1
      if number_table[x] == 2 then
        table.insert(get, id)
      else
        table.insert(throw, id)
      end
    end
    local result = room:askToArrangeCards(player, {
      skill_name = jiufa.name,
      card_map = {card_ids},
      prompt = "#jiufa",
      box_size = 0,
      max_limit = {9, 9},
      min_limit = {0, #get},
      pattern = ".",
      poxi_type = "jiufa",
      default_choice = {throw, get}
    })
    throw = result[1]
    get = result[2]
    if #get > 0 then
      room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, jiufa.name, "", true, player.id)
    end
    room:cleanProcessingArea(card_ids, jiufa.name)
  end,
})

jiufa.on_lose = function(self, player)
  player.room:setPlayerMark(player, "@$jiufa", 0)
end

return jiufa
