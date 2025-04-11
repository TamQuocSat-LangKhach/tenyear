local ty_ex__xiansi = fk.CreateSkill {
  name = "ty_ex__xiansi"
}

Fk:loadTranslationTable{
  ['ty_ex__xiansi&'] = '陷嗣',
  ['ty_ex__xiansi'] = '陷嗣',
  ['ty_ex__xiansi_ni'] = '逆',
  [':ty_ex__xiansi&'] = '当你需使用【杀】时，你可以弃置刘封的两张“逆”，视为对其使用一张【杀】。',
}

ty_ex__xiansi:addEffect('viewas', {
  anim_type = "negative",
  pattern = "slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("slash")
    c.skillName = skill.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
      local p = room:getPlayerById(id)
      if p:hasSkill(ty_ex__xiansi, true) and #p:getPile("ty_ex__xiansi_ni") > 1 then
        local cards = table.random(p:getPile("ty_ex__xiansi_ni"), 2)
        room:moveCards({
          from = id,
          ids = cards,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = skill.name,
        })
        break
      end
    end
  end,
  enabled_at_play = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return (p:hasSkill(ty_ex__xiansi, true) and #p:getPile("ty_ex__xiansi_ni") > 1) end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and table.find(Fk:currentRoom().alive_players, function(p)
      return (p:hasSkill(ty_ex__xiansi, true) and #p:getPile("ty_ex__xiansi_ni") > 1) end)
  end,
})

ty_ex__xiansi:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    if from:hasSkill(ty_ex__xiansi, true) then
      return card.trueName == "slash" and table.contains(card.skillNames, skill.name) and
        not (to:hasSkill(ty_ex__xiansi, true) and #to:getPile("ty_ex__xiansi_ni") > 1)
    end
  end,
})

return ty_ex__xiansi
