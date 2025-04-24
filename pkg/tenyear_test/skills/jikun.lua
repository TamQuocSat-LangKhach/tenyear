local jikun = fk.CreateSkill{
  name = "jikun",
}

Fk:loadTranslationTable{
  ["jikun"] = "济困",
  [":jikun"] = "每当你失去五张牌后，你可以选择一名其他角色，令其随机获得每名手牌数最多的角色各一张牌。",

  ["@jikun"] = "济困",
  ["#jikun-choose"] = "济困：令一名角色获得手牌数最多的角色各一张牌",

  ["$jikun1"] = "",
  ["$jikun2"] = "",
}

jikun:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(jikun.name) then
      for _, move in ipairs(data) do
        if move.extra_data and move.extra_data.jikun and table.contains(move.extra_data.jikun, player.id) then
          return #player.room:getOtherPlayers(player, false) > 0 and
            table.find(player.room.alive_players, function (p)
              return not p:isNude()
            end)
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = jikun.name,
      prompt = "#jikun-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local targets = table.filter(room.alive_players, function (p)
      return table.every(room.alive_players, function (q)
        return p:getHandcardNum() >= q:getHandcardNum()
      end)
    end)
    table.removeOne(targets, to)
    targets = table.filter(targets, function (p)
      return not p:isNude()
    end)
    if #targets == 0 then return end
    room:sortByAction(targets)
    local moves = {}
    for _, p in ipairs(targets) do
      table.insert(moves, {
        ids = table.random(p:getCardIds("he"), 1),
        from = p,
        to = to,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        skillName = jikun.name,
        proposer = to,
        moveVisible = false,
      })
    end
    room:moveCards(table.unpack(moves))
  end,

  can_refresh = function (self, event, target, player, data)
    if player:hasSkill(jikun.name, true) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.from == player and player:hasSkill(jikun.name, true) then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            room:addPlayerMark(player, "@jikun", 1)
            while player:getMark("@jikun") > 5 do
              room:removePlayerMark(player, "@jikun", 5)
              move.extra_data = move.extra_data or {}
              move.extra_data.jikun = move.extra_data.jikun or {}
              table.insertIfNeed(move.extra_data.jikun, player.id)
            end
          end
        end
      end
    end
  end,
})

jikun:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@jikun", 0)
end)

return jikun
