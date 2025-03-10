local ty_ex__huomo = fk.CreateSkill {
  name = "ty_ex__huomo"
}

Fk:loadTranslationTable{
  ['ty_ex__huomo'] = '活墨',
  ['#ty_ex__huomo-card'] = '活墨：将一张黑色非基本牌置于牌堆顶',
  [':ty_ex__huomo'] = '当你需要使用基本牌时（每种牌名每回合限一次），你可以将一张黑色非基本牌置于牌堆顶，视为使用此基本牌。',
  ['$ty_ex__huomo1'] = '笔墨抒胸臆，妙手成汗青。',
  ['$ty_ex__huomo2'] = '胸蕴大家之行，则下笔如有神助。',
}

ty_ex__huomo:addEffect('viewas', {
  pattern = ".|.|.|.|.|basic",
  prompt = function ()
    return "#ty_ex__huomo-card"
  end,
  interaction = function()
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, ty_ex__huomo.name, all_names, {}, Self:getTableMark(ty_ex__huomo.name .. "-turn"))
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = function (self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.type ~= Card.TypeBasic and card.color == Card.Black
  end,
  before_use = function (self, player, use)
    local room = player.room
    room:addTableMark(player, ty_ex__huomo.name .. "-turn", use.card.trueName)
    local put = use.card:getMark(ty_ex__huomo.name)
    if put ~= 0 and table.contains(player:getCardIds("he"), put) then
      room:moveCards({
        ids = {put},
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = ty_ex__huomo.name,
        proposer = player.id,
        moveVisible = true,
      })
    end
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:setMark(ty_ex__huomo.name, cards[1])
    card.skillName = ty_ex__huomo.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isNude()
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isNude()
  end,
})

return ty_ex__huomo
