local zhimin = fk.CreateSkill {
  name = "zhimin"
}

Fk:loadTranslationTable{
  ['zhimin'] = '置民',
  ['@@zhimin-inhand'] = '民',
  ['#zhimin-choose'] = '置民：选择1-%arg名角色，获得这些角色手牌中点数最小的牌',
  [':zhimin'] = '锁定技，每轮开始时，你选择至多X名其他角色（x为你的体力值），获得这些角色点数最小的一张手牌。你于回合外得到牌后，这些牌称为“民”。当你失去“民”后，你将手牌补至体力上限。',
  ['$zhimin1'] = '渤海虽阔，亦不及朕胸腹之广。',
  ['$zhimin2'] = '民众渡海而来，当筑梧居相待。',
}

zhimin:addEffect(fk.RoundStart, {
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(zhimin.name) then return false end
    return true
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p ~= player and not p:isKongcheng()
    end)
    if #targets == 0 then return false end
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = player.hp,
      prompt = "#zhimin-choose:::" .. tostring(player.hp),
      skill_name = zhimin.name,
      cancelable = false,
    })
    local to, card, n
    local toObtain = {}
    for _, pid in ipairs(Util.getIdsFromPlayers(targets)) do
      to = room:getPlayerById(pid)
      local cards = {}
      for _, id in ipairs(to:getCardIds(Player.Hand)) do
        card = Fk:getCardById(id)
        if #cards == 0 then
          table.insert(cards, id)
          n = card.number
        else
          if n > card.number then
            n = card.number
            cards = {id}
          elseif n == card.number then
            table.insert(cards, id)
          end
        end
      end
      if #cards > 0 then
        table.insert(toObtain, table.random(cards))
      end
    end
    if #toObtain > 0 then
      room:moveCardTo(toObtain, Player.Hand, player, fk.ReasonPrey, zhimin.name, "", false, player.id)
    end
  end,
})

zhimin:addEffect(fk.AfterCardsMove, {
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    local cards1, cards2 = {}, {}
    local handcards = player:getCardIds(Player.Hand)
    local mark = player:getTableMark("zhimin_record")
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        if player.phase == Player.NotActive then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if table.contains(handcards, id) then
              table.insert(cards1, id)
            end
          end
        end
      elseif move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if info.fromArea == Player.Hand and table.contains(mark, id) then
            table.insert(cards2, id)
          end
        end
      end
    end
    if #cards1 > 0 or #cards2 > 0 then
      event:setCostData(self, {cards1, cards2})
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local zhimin_data = table.simpleClone(event:getCostData(self))
    local mark = player:getTableMark("zhimin_record")
    if #zhimin_data[1] > 0 then
      table.insertTableIfNeed(mark, zhimin_data[1])
      for _, id in ipairs(zhimin_data[1]) do
        room:setCardMark(Fk:getCardById(id), "@@zhimin-inhand", 1)
      end
    end
    for _, id in ipairs(zhimin_data[2]) do
      table.removeOne(mark, id)
    end
    room:setPlayerMark(player, "zhimin_record", mark)
    if #zhimin_data[2] > 0 then
      local num = player.maxHp - player:getHandcardNum()
      if num > 0 then
        player:drawCards(num, zhimin.name)
      end
    end
  end,
})

return zhimin
