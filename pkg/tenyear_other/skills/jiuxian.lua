local jiuxian = fk.CreateSkill {
  name = "jiuxian",
}

Fk:loadTranslationTable{
  ["jiuxian"] = "酒仙",
  [":jiuxian"] = "你使用【酒】无次数限制，你可以将多目标锦囊牌当【酒】使用。",

  ["#jiuxian"] = "酒仙：你可以将多目标锦囊牌当【酒】使用",

  ["$jiuxian1"] = "地若不爱酒，地应无酒泉。",
  ["$jiuxian2"] = "天若不爱酒，酒星不在天。",
}

jiuxian:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "analeptic",
  prompt = "#jiuxian",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).multiple_targets
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local card = Fk:cloneCard("analeptic")
    card:addSubcard(cards[1])
    card.skillName = jiuxian.name
    return card
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

jiuxian:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and player:hasSkill(jiuxian.name) and skill.trueName == "analeptic_skill" and scope == Player.HistoryTurn
  end,
})

return jiuxian
