local shouxing = fk.CreateSkill {
  name = "shouxing",
}

Fk:loadTranslationTable{
  ["shouxing"] = "狩星",
  [":shouxing"] = "你可以将X张牌当一张不计次数的【杀】对一名攻击范围外的角色使用（X为你计算与该角色的距离）。",

  ["#shouxing"] = "狩星：将任意张牌当一张不计次数的【杀】对一名攻击范围外、距离为牌数的角色使用",

  ["$shouxing1"] = "古时后羿射日，今我以星为狩。",
  ["$shouxing2"] = "柔荑挽雕弓，箭出大星落。",
}

shouxing:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#shouxing",
  handly_pile = true,
  card_filter = Util.TrueFunc,
  view_as = function(self, player, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = shouxing.name
    card:addSubcards(cards)
    return card
  end,
  before_use = function (self, player, use)
    use.extraUse = true
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})

shouxing:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and table.contains(card.skillNames, shouxing.name) and
      (from:distanceTo(to) ~= #card.subcards or from:inMyAttackRange(to))
  end,
})

shouxing:addEffect("targetmod", {
  bypass_distances = function(self, player, skillName, card)
    return skillName.trueName == "slash_skill" and card and
      table.contains(card.skillNames, shouxing.name)
  end,
  bypass_times = function(self, player, skillName, scope, card)
    return skillName.trueName == "slash_skill" and scope == Player.HistoryPhase and card and
      table.contains(card.skillNames, shouxing.name)
  end,
})

return shouxing
