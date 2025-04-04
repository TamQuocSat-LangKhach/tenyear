local jiusi = fk.CreateSkill {
  name = "jiusi",
}

Fk:loadTranslationTable{
  ["jiusi"] = "纠思",
  [":jiusi"] = "每回合限一次，当你需要使用基本牌时，你可以翻面，视为使用一张基本牌。",

  ["#jiusi"] = "纠思：你可以翻面，视为使用一张基本牌",

  ["$jiusi1"] = "双姝出宫墙，飞雪白了少年头。",
  ["$jiusi2"] = "心鹿徙南北，我何处西东？",
}

local U = require "packages/utility/utility"

jiusi:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#jiusi",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(jiusi.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_names = all_names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = jiusi.name
    return card
  end,
  before_use = function (self, player, use)
    player:turnOver()
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(jiusi.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(jiusi.name, Player.HistoryTurn) == 0
  end,
})

return jiusi
