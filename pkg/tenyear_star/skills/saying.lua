local saying = fk.CreateSkill {
  name = "saying"
}

Fk:loadTranslationTable{
  ['saying'] = '飒影',
  ['#saying-nil'] = '发动 飒影，没有可使用的牌',
  [':saying'] = '每轮每种牌名限一次，当你需要使用【杀】或【闪】时，你可以使用一张装备牌，然后视为使用之；当你需要使用【桃】或【酒】时，你可以收回装备区里的一张牌，然后视为使用之。',
  ['$saying1'] = '倩影映江汀，巾帼犹飒爽！',
  ['$saying2'] = '我有一袭红袖，欲揾英雄泪！'
}

saying:addEffect('viewas', {
  pattern = "slash,jink,peach,analeptic",
  prompt = function (self)
    if self.interaction.data == nil then
      return "#saying-nil"
    end
    return "#saying-" .. self.interaction.data
  end,
  interaction = function(self, player)
    local all_names = {"slash", "jink", "peach", "analeptic"}
    local names = U.getViewAsCardNames(player, saying.name, all_names, {}, player:getTableMark("saying-round"))
    if #names == 0 then return end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    if self.interaction.data == "slash" or self.interaction.data == "jink" then
      if Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip then return false end
      local card = Fk:getCardById(to_select)
      return card.type == Card.TypeEquip and player:canUseTo(card, player)
    elseif self.interaction.data == "peach" or self.interaction.data == "analeptic" then
      return Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip
    end
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards == 0 then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:setMark(saying.name, cards[1])
    card.skillName = saying.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:addTableMark(player, "saying-round", use.card.trueName)
    local card_id = use.card:getMark(saying.name)
    if use.card.trueName == "slash" or use.card.trueName == "jink" then
      room:useCard{
        from = player.id,
        tos = { {player.id} },
        card = Fk:getCardById(card_id),
      }
    elseif use.card.trueName == "peach" or use.card.trueName == "analeptic" then
      room:obtainCard(player, card_id, true, fk.ReasonPrey, player.id, saying.name)
    end
  end,
  enabled_at_play = function(self, player)
    local card
    local mark = player:getTableMark("saying-round")
    return not table.every({"slash", "peach", "analeptic"}, function(name)
      if table.contains(mark, name) then return true end
      card = Fk:cloneCard(name)
      card.skillName = saying.name
      return not player:canUse(card) or player:prohibitUse(card)
    end)
  end,
  enabled_at_response = function(self, player, response)
    if response or Fk.currentResponsePattern == nil then return false end
    local card
    local mark = player:getTableMark("saying-round")
    return not table.every({"slash", "jink", "peach", "analeptic"}, function(name)
      if table.contains(mark, name) then return true end
      card = Fk:cloneCard(name)
      card.skillName = saying.name
      return not Exppattern:Parse(Fk.currentResponsePattern):match(card) or player:prohibitUse(card)
    end)
  end,
})

return saying
