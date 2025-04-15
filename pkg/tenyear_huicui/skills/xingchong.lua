local xingchong = fk.CreateSkill {
  name = "xingchong",
}

Fk:loadTranslationTable{
  ["xingchong"] = "幸宠",
  [":xingchong"] = "每轮游戏开始时，你可以摸任意张牌并展示任意张牌（摸牌和展示牌的总数不能超过你的体力上限）。若如此做，"..
  "本轮内当你失去一张以此法展示的手牌后，你摸两张牌。",

  ["#xingchong-invoke"] = "幸宠：你可以摸牌、展示牌合计至多%arg张，本轮失去展示的牌后摸两张牌",
  ["#xingchong-draw"] = "幸宠：选择摸牌数",
  ["#xingchong-card"] = "幸宠：展示至多%arg张牌，本轮失去一张展示牌后摸两张牌",
  ["@@xingchong-inhand-round"] = "幸宠",

  ["$xingchong1"] = "佳人有荣幸，好女天自怜。",
  ["$xingchong2"] = "世间万般宠爱，独聚我于一身。",
}

xingchong:addEffect(fk.RoundStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xingchong.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = xingchong.name,
      prompt = "#xingchong-invoke:::"..player.maxHp,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player.maxHp
    local choices = {}
    local i1 = 0
    if player:isKongcheng() then
      i1 = 1
    end
    for i = i1, n, 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xingchong.name,
      prompt = "#xingchong-draw",
    })
    if choice ~= "0" then
      player:drawCards(tonumber(choice), xingchong.name)
    end
    if player:isKongcheng() then return end
    n = n - tonumber(choice)
    if n < 1 then return false end
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = n,
      include_equip = false,
      skill_name = xingchong.name,
      cancelable = true,
      prompt = "#xingchong-card:::"..n,
    })
    if #cards > 0 then
      player:showCards(cards)
      if not player.dead then
        local mark = {}
        for _, id in ipairs(cards) do
          if table.contains(player:getCardIds("h"), id) then
            table.insertIfNeed(mark, id)
            room:setCardMark(Fk:getCardById(id), "@@xingchong-inhand-round", 1)
          end
        end
        room:setPlayerMark(player, "xingchong-round", mark)
      end
    end
  end,
})

xingchong:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark("xingchong-round") ~= 0 then
      local mark = player:getMark("xingchong-round")
      for _, move in ipairs(event.data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and table.contains(mark, info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = table.simpleClone(player:getTableMark("xingchong-round"))
    local x = 0
    for _, move in ipairs(event.data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and table.removeOne(mark, info.cardId) then
            x = x + 2
          end
        end
      end
    end
    room:setPlayerMark(player, "xingchong-round", #mark > 0 and mark or 0)
    player:drawCards(x, xingchong.name)
  end,
})

return xingchong
