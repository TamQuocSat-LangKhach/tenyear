local lifengc = fk.CreateSkill {
  name = "lifengc"
}

Fk:loadTranslationTable{
  ['lifengc'] = '砺锋',
  [':lifengc'] = '你可以将一张本回合未被使用过的颜色的手牌当不计次数的【杀】或【无懈可击】使用。',
  ['$lifengc1'] = '锋出百砺，健卒亦如是。',
  ['$lifengc2'] = '强军者，必校之以三九，练之三伏。',
}

lifengc:addEffect('viewas', {
  pattern = "slash,nullification",
  interaction = function()
    local names = {}
    if Fk.currentResponsePattern == nil and Self:canUse(Fk:cloneCard("slash")) then
      table.insertIfNeed(names, "slash")
    else
      for _, name in ipairs({"slash", "nullification"}) do
        if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name)) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and
      player:getMark("lifengc_"..Fk:getCardById(to_select):getColorString().."-turn") == 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card_name = self.interaction.data
    local card = Fk:cloneCard(card_name)
    card.skillName = lifengc.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function (self, player, use)
    use.extraUse = true
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isKongcheng()
  end,
})

lifengc:addEffect(fk.AfterCardUseDeclared, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lifengc) and data.card.color ~= Card.NoColor
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "lifengc_"..data.card:getColorString().."-turn", 1)
  end,
})

return lifengc
