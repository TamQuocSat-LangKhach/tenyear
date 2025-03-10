local ty__fanghun = fk.CreateSkill {
  name = "ty__fanghun"
}

Fk:loadTranslationTable{
  ['ty__fanghun'] = '芳魂',
  ['#ty__fanghun-viewas'] = '发动 芳魂，弃1枚”梅影“，将【杀】当【闪】、【闪】当【杀】使用或打出，并摸一张牌',
  [':ty__fanghun'] = '当你使用【杀】指定目标后或成为【杀】的目标后，你获得1个“梅影”标记；你可以移去1个“梅影”标记发动〖龙胆〗并摸一张牌。',
  ['$ty__fanghun1'] = '芳年华月，不负期望。',
  ['$ty__fanghun2'] = '志洁行芳，承父高志。',
}

ty__fanghun:addEffect('viewas', {
  prompt = "#ty__fanghun-viewas",
  pattern = "slash,jink",
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    local _c = Fk:getCardById(to_select)
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    else
      return false
    end
    return (Fk.currentResponsePattern == nil and c.skill:canUse(player, c)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then
      return nil
    end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    end
    c.skillNames = c.skillNames or {}
    table.insert(c.skillNames, ty__fanghun.name)
    table.insert(c.skillNames, "longdan")
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  enabled_at_response = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  before_use = function(self, player, data)
    player.room:removePlayerMark(player, "@meiying")
  end,

  on_lose = function (skill, player)
    player.room:setPlayerMark(player, "@meiying", 0)
  end,
})

ty__fanghun:addEffect(fk.TargetSpecified + fk.TargetConfirmed, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__fanghun) and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ty__fanghun.name)
    if not table.contains(data.card.skillNames, ty__fanghun.name) or event == fk.TargetConfirmed then
      player:broadcastSkillInvoke(ty__fanghun.name)
    end
    room:addPlayerMark(player, "@meiying")
  end,
})

ty__fanghun:addEffect(fk.CardUseFinished + fk.CardRespondFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player == target and table.contains(data.card.skillNames, ty__fanghun.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, ty__fanghun.name)
  end,
})

return ty__fanghun
