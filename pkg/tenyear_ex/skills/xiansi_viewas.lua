local xiansi_viewas = fk.CreateSkill {
  name = "ty_ex__xiansi&",
}

Fk:loadTranslationTable{
  ["ty_ex__xiansi&"] = "陷嗣",
  [":ty_ex__xiansi&"] = "当你需使用【杀】时，你可以移去刘封的两张“逆”，视为对其使用一张【杀】。",

  ["#ty_ex__xiansi&"] = "陷嗣：你可以移去刘封的两张“逆”，视为对其使用一张【杀】",
}

xiansi_viewas:addEffect("viewas", {
  mute = true,
  pattern = "slash",
  prompt = "#ty_ex__xiansi&",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("slash")
    c.skillName = xiansi_viewas.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    local src = table.find(use.tos, function (p)
      return p:hasSkill("ty_ex__xiansi") and #p:getPile("ty_ex__xiansi_ni") > 1
    end)
    if src == nil then return "" end
    player:broadcastSkillInvoke("ty_ex__xiansi")
    room:notifySkillInvoked(player, "ty_ex__xiansi", "negative")
    local cards = table.random(src:getPile("ty_ex__xiansi_ni"), 2)
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, "ty_ex__xiansi", nil, true, player)
  end,
  enabled_at_play = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill("ty_ex__xiansi") and #p:getPile("ty_ex__xiansi_ni") > 1
    end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill("ty_ex__xiansi") and #p:getPile("ty_ex__xiansi_ni") > 1
    end)
  end,
})

xiansi_viewas:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return table.contains(card.skillNames, xiansi_viewas.name) and
      not (to:hasSkill("ty_ex__xiansi") and #to:getPile("ty_ex__xiansi_ni") > 1)
  end,
})

return xiansi_viewas
