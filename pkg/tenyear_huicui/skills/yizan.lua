local yizan = fk.CreateSkill {
  name = "ty__yizan",
  dynamic_desc = function (self, player, lang)
    if player:usedSkillTimes("ty__longyuan", Player.HistoryGame) > 0 then
      return "ty__yizan_update"
    end
  end,
}

Fk:loadTranslationTable{
  ["ty__yizan"] = "翊赞",
  [":ty__yizan"] = "你可以将两张牌（其中至少一张是基本牌）当任意基本牌使用或打出。",

  [":ty__yizan_update"] = "你可以将一张基本牌当任意基本牌使用或打出。",

  ["#ty__yizan"] = "翊赞：你可以将两张牌（其中至少一张是基本牌）当任意基本牌使用或打出",
  ["#ty__yizan_update"] = "翊赞：你可以将一张基本牌当任意基本牌使用或打出",

  ["$ty__yizan1"] = "擎龙胆枪锋砺天，抱青釭霜刃谁试！",
  ["$ty__yizan2"] = "束坚甲以拥豹尾，立长戈而伐不臣。",
}

local U = require "packages/utility/utility"

yizan:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = function(self, player, selected_cards)
    return player:usedSkillTimes("ty__longyuan", Player.HistoryGame) > 0 and "#ty__yizan_update" or "#ty__yizan"
  end,
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(yizan.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return Fk:getCardById(to_select).type == Card.TypeBasic
    elseif player:usedSkillTimes("ty__longyuan", Player.HistoryGame) == 0 then
      return #selected == 1
    end
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    if player:usedSkillTimes("ty__longyuan", Player.HistoryGame) > 0 then
      if #cards ~= 1 then return end
    else
      if #cards ~= 2 then return end
    end
    if not table.find(cards, function(id)
      return Fk:getCardById(id).type == Card.TypeBasic
    end) then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = yizan.name
    return card
  end,
})

return yizan
