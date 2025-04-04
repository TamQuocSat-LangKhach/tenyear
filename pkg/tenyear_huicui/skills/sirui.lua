local sirui = fk.CreateSkill {
  name = "sirui",
}

Fk:loadTranslationTable{
  ["sirui"] = "思锐",
  [":sirui"] = "出牌阶段限一次，你可以将一张牌当牌名字数相等的基本牌或普通锦囊牌使用（无距离和次数限制）。",

  ["#sirui"] = "思锐：将一张牌当牌名字数相等的牌使用（无距离和次数限制）",

  ["$sirui1"] = "暑气可借酒气消，此间艳阳最佐酒！",
  ["$sirui2"] = "诸君饮泥而醉，举世唯我独醒！",
}

local U = require "packages/utility/utility"

sirui:addEffect("viewas", {
  prompt = "#sirui",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("bt")
    local names = player:getViewAsCardNames(sirui.name, all_names)
    if #names > 0 then
      return U.CardNameBox {choices = names, all_choices = all_names}
    end
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 or not self.interaction.data then return false end
    local card = Fk:cloneCard(self.interaction.data)
    return Fk:translate(card.trueName, "zh_CN"):len() == Fk:translate(Fk:getCardById(to_select).trueName, "zh_CN"):len()
  end,
  view_as = function(self, player, cards)
    if #cards == 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = sirui.name
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(sirui.name, Player.HistoryPhase) == 0
  end,
})

sirui:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, sirui.name)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, sirui.name)
  end,
})

return sirui
