local dujun = fk.CreateSkill {
  name = "dujun",
}

Fk:loadTranslationTable{
  ["dujun"] = "笃君",
  [":dujun"] = "游戏开始时，你选择一名其他角色：<br>"..
  "你不能响应其使用的牌；<br>"..
  "你与其每回合首次造成或受到伤害后，你可以摸两张牌，然后可以将这些牌交给一名角色。",

  ["#dujun-choose"] = "笃君：请选择“笃君”角色",
  ["@dujun"] = "笃君",
  ["#dujun-give"] = "笃君：你可以将这些牌交给一名角色",

  ["$dujun1"] = "慷慨悲歌，以抗凶逆。",
  ["$dujun2"] = "忧惶昼夜，抗之以歌。",
}

dujun:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dujun.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      prompt = "#dujun-choose",
      skill_name = dujun.name,
      cancelable = false,
    })[1]
    room:setPlayerMark(player, dujun.name, to.id)
    room:addTableMark(to, "@dujun", player.id)
  end,
})

dujun:addEffect(fk.CardUsing, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dujun.name) and player:getMark(dujun.name) == target.id and
      (data.card:isCommonTrick() or (data.card.trueName == "slash" and table.contains(data.tos, player)))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insert(data.disresponsiveList, player)
  end,
})

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(2, dujun.name)
    if player.dead then return end
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = dujun.name,
      prompt = "#dujun-give",
      cancelable = true,
    })
    if #to > 0 and to[1] ~= player then
      room:moveCardTo(cards, Card.PlayerHand, to[1], fk.ReasonGive, dujun.name, nil, false, player)
    end
  end,
}

dujun:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(dujun.name) and target and (target == player or player:getMark(dujun.name) == target.id) then
      local damage_events = player.room.logic:getActualDamageEvents(999, function (e)
        return e.data.from == target
      end, Player.HistoryTurn)
      return #damage_events > 0 and damage_events[#damage_events].data == data
    end
  end,
  on_use = spec.on_use,
})

dujun:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(dujun.name) and (target == player or player:getMark(dujun.name) == target.id) then
      local damage_events = player.room.logic:getActualDamageEvents(999, function (e)
        return e.data.to == target
      end, Player.HistoryTurn)
      return #damage_events > 0 and damage_events[#damage_events].data == data
    end
  end,
  on_use = spec.on_use,
})

dujun:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, dujun.name, 0)
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, "@dujun", player.id)
  end
end)

return dujun
