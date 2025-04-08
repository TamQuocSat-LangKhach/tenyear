local gue = fk.CreateSkill {
  name = "gue",
}

Fk:loadTranslationTable{
  ["gue"] = "孤扼",
  [":gue"] = "每名其他角色的回合内限一次，当你需要使用或打出【杀】或【闪】时，你可以：展示所有手牌，若其中【杀】和【闪】的总数小于2，"..
  "视为你使用或打出之。",

  ["#gue"] = "孤扼：展示所有手牌，若【杀】【闪】总数不大于1，视为你使用或打出之",

  ["$gue1"] = "哀兵必胜，况吾众志成城。",
  ["$gue2"] = "扼守孤城，试问万夫谁开？",
}

local U = require "packages/utility/utility"

gue:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "slash,jink",
  prompt = "#gue",
  interaction = function(self, player)
    local all_names = {"slash", "jink"}
    local names = player:getViewAsCardNames(gue.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = gue.name
    return card
  end,
  before_use = function(self, player)
    local cards = table.simpleClone(player:getCardIds("h"))
    player:showCards(cards)
    if #table.filter(cards, function(id)
      return table.contains({"slash", "jink"}, Fk:getCardById(id).trueName)
    end) > 1 then
      return ""
    end
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return player:usedSkillTimes(gue.name, Player.HistoryTurn) == 0 and Fk:currentRoom().current ~= player and
      not player:isKongcheng()
  end,
})

return gue
