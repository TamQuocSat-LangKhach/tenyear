local fanghun = fk.CreateSkill {
  name = "ty__fanghun",
}

Fk:loadTranslationTable{
  ["ty__fanghun"] = "芳魂",
  [":ty__fanghun"] = "当你使用【杀】指定目标后或成为【杀】的目标后，你获得1个“梅影”标记；你可以移去1个“梅影”标记发动〖龙胆〗并摸一张牌。",

  ["#ty__fanghun"] = "芳魂：你可以移去1个“梅影”标记，发动〖龙胆〗并摸一张牌",

  ["$ty__fanghun1"] = "芳年华月，不负期望。",
  ["$ty__fanghun2"] = "志洁行芳，承父高志。",
}

fanghun:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@meiying", 0)
end)

fanghun:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = "#ty__fanghun",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    local card = Fk:getCardById(to_select)
    if card.trueName == "slash" then
      return #player:getViewAsCardNames(fanghun.name, {"jink"}) > 0
    elseif card.name == "jink" then
      return #player:getViewAsCardNames(fanghun.name, {"slash"}) > 0
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    end
    c.skillNames = c.skillNames or {}
    table.insert(c.skillNames, fanghun.name)
    table.insert(c.skillNames, "longdan")
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@meiying", 1)
  end,
  after_use = function (self, player, use)
    if not player.dead then
      player:drawCards(1, fanghun.name)
    end
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  enabled_at_response = function(self, player, response)
    return player:getMark("@meiying") > 0
  end,
})

fanghun:addEffect(fk.TargetSpecified, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(fanghun.name) and data.card.trueName == "slash" and data.firstTarget
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@meiying", 1)
  end,
})
fanghun:addEffect(fk.TargetConfirmed, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(fanghun.name) and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@meiying", 1)
  end,
})

return fanghun
