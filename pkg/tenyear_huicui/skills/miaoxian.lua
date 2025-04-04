local miaoxian = fk.CreateSkill {
  name = "miaoxian",
}

Fk:loadTranslationTable{
  ["miaoxian"] = "妙弦",
  [":miaoxian"] = "每回合限一次，你可以将手牌中的唯一黑色牌当任意一张普通锦囊牌使用；当你使用手牌中的唯一红色牌时，你摸一张牌。",

  ["#miaoxian"] = "妙弦：将手牌中唯一的黑色牌当任意锦囊牌使用",

  ["$miaoxian1"] = "女为悦者容，士为知己死。",
  ["$miaoxian2"] = "与君高歌，请君侧耳。",
}

local U = require "packages/utility/utility"

miaoxian:addEffect("viewas", {
  pattern = ".|.|.|.|.|trick",
  prompt = "#miaoxian",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("t")
    local black = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color == Card.Black
    end)
    local names = player:getViewAsCardNames(miaoxian.name, all_names, black)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local black = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color == Card.Black
    end)
    if #black ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(black[1])
    card.skillName = miaoxian.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedEffectTimes(miaoxian.name, Player.HistoryTurn) == 0 and
      #table.filter(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black
      end) == 1
  end,
  enabled_at_response = function(self, player, response)
    return not response and
      player:usedEffectTimes(miaoxian.name, Player.HistoryTurn) == 0 and
      #table.filter(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black
      end) == 1
  end,
})

miaoxian:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(miaoxian.name) and
      not table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Red
      end) and data.card.color == Card.Red and
      data:IsUsingHandcard(player) and #Card:getIdList(data.card) == 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, miaoxian.name)
  end,
})

return miaoxian
