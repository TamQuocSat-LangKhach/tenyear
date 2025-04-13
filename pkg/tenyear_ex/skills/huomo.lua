local huomo = fk.CreateSkill {
  name = "ty_ex__huomo",
}

Fk:loadTranslationTable{
  ["ty_ex__huomo"] = "活墨",
  [":ty_ex__huomo"] = "当你需要使用基本牌时（每种牌名每回合限一次），你可以将一张黑色非基本牌置于牌堆顶，视为使用此基本牌。",

  ["#ty_ex__huomo"] = "活墨：将一张黑色非基本牌置于牌堆顶，视为使用一张基本牌",

  ["$ty_ex__huomo1"] = "笔墨抒胸臆，妙手成汗青。",
  ["$ty_ex__huomo2"] = "胸蕴大家之行，则下笔如有神助。",
}

local U = require "packages/utility/utility"

huomo:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = "#ty_ex__huomo",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(huomo.name, all_names, nil, player:getTableMark("ty_ex__huomo-turn"))
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_names = all_names}
  end,
  card_filter = function (self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.type ~= Card.TypeBasic and card.color == Card.Black
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = huomo.name
    self.cost_data = cards
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    room:addTableMark(player, "ty_ex__huomo-turn", use.card.trueName)
    room:moveCards({
      ids = self.cost_data,
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = huomo.name,
      proposer = player,
      moveVisible = true,
    })
  end,
  enabled_at_play = function(self, player)
    return not player:isNude()
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isNude() and
      #player:getViewAsCardNames(huomo.name, Fk:getAllCardNames("b"), nil, player:getTableMark("ty_ex__huomo-turn"))
  end,
})

huomo:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "ty_ex__huomo-turn", 0)
end)

return huomo
