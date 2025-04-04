local zhimin = fk.CreateSkill {
  name = "zhimin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhimin"] = "置民",
  [":zhimin"] = "锁定技，每轮开始时，你选择至多X名其他角色（x为你的体力值），获得这些角色点数最小的一张手牌。你于回合外得到牌后，"..
  "这些牌称为“民”。当你失去“民”后，你将手牌补至体力上限。",

  ["@@zhimin-inhand"] = "民",
  ["#zhimin-choose"] = "置民：选择至多%arg名角色，获得这些角色手牌中点数最小的牌",

  ["$zhimin1"] = "渤海虽阔，亦不及朕胸腹之广。",
  ["$zhimin2"] = "民众渡海而来，当筑梧居相待。",
}

zhimin:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhimin.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isKongcheng()
    end)
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = player.hp,
      prompt = "#zhimin-choose:::" .. player.hp,
      skill_name = zhimin.name,
      cancelable = false,
    })
    room:sortByAction(targets)
    local cards = {}
    for _, to in ipairs(targets) do
      local ids = table.filter(to:getCardIds("h"), function (id)
        return table.every(to:getCardIds("h"), function (id2)
          return Fk:getCardById(id).number <= Fk:getCardById(id2).number
        end)
      end)
      if #ids > 0 then
        table.insert(cards, table.random(ids))
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, zhimin.name, nil, false, player)
    end
  end,
})

zhimin:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhimin.name) then
      local cards1, cards2 = {}, {}
      local mark = player:getTableMark("zhimin_record")
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand and
          (player.room.current ~= player or player.phase == Player.NotActive) then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) then
              table.insert(cards1, info.cardId)
            end
          end
        elseif move.from == player then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if info.fromArea == Player.Hand and table.contains(mark, id) then
              table.insert(cards2, id)
            end
          end
        end
      end
      if #cards1 > 0 or #cards2 > 0 then
        event:setCostData(self, {extra_data = {cards1, cards2}})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = table.simpleClone(event:getCostData(self).extra_data)
    local mark = player:getTableMark("zhimin_record")
    if #dat[1] > 0 then
      table.insertTableIfNeed(mark, dat[1])
      for _, id in ipairs(dat[1]) do
        room:setCardMark(Fk:getCardById(id), "@@zhimin-inhand", 1)
      end
    end
    for _, id in ipairs(dat[2]) do
      table.removeOne(mark, id)
    end
    room:setPlayerMark(player, "zhimin_record", mark)
    if #dat[2] > 0 then
      local num = player.maxHp - player:getHandcardNum()
      if num > 0 then
        player:drawCards(num, zhimin.name)
      end
    end
  end,
})

zhimin:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, zhimin.name, 0)
  room:setPlayerMark(player, "zhimin_record", 0)
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id), "@@zhimin-inhand", 0)
  end
end)

return zhimin
