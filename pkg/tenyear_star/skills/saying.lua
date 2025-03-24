local saying = fk.CreateSkill {
  name = "saying",
}

Fk:loadTranslationTable{
  ["saying"] = "飒影",
  [":saying"] = "每轮每种牌名限一次，当你需要使用【杀】或【闪】时，你可以使用一张装备牌，然后视为使用之；当你需要使用【桃】或【酒】时，"..
  "你可以收回装备区里的一张牌，然后视为使用之。",

  ["#saying1"] = "飒影：使用一张装备牌，然后视为使用【%arg】",
  ["#saying2"] = "飒影：收回一张装备，然后视为使用【%arg】",
  ["#saying-nil"] = "飒影：没有可使用的牌",

  ["$saying1"] = "倩影映江汀，巾帼犹飒爽！",
  ["$saying2"] = "我有一袭红袖，欲揾英雄泪！"
}

local U = require "packages/utility/utility"

saying:addEffect("viewas", {
  pattern = "slash,jink,peach,analeptic",
  prompt = function (self, player)
    if self.interaction.data == nil then
      return "#saying-nil"
    elseif table.contains({"slash", "jink"}, self.interaction.data) then
      return "#saying1:::"..self.interaction.data
    elseif table.contains({"peach", "analeptic"}, self.interaction.data) then
      return "#saying2:::"..self.interaction.data
    end
  end,
  interaction = function(self, player)
    local all_names = {"slash", "jink", "peach", "analeptic"}
    local names = player:getViewAsCardNames(saying.name, all_names, nil, player:getTableMark("saying-round"))
    if #names == 0 then return end
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      if self.interaction.data == "slash" or self.interaction.data == "jink" then
        if table.contains(player:getHandlyIds(), to_select) then
          local card = Fk:getCardById(to_select)
          return card.type == Card.TypeEquip and player:canUseTo(card, player)
        end
      elseif self.interaction.data == "peach" or self.interaction.data == "analeptic" then
        return table.contains(player:getCardIds("e"), to_select)
      end
    end
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data or #cards == 0 then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    self.cost_data = cards
    card.skillName = saying.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:addTableMark(player, "saying-round", use.card.trueName)
    local id = self.cost_data[1]
    if use.card.trueName == "slash" or use.card.trueName == "jink" then
      room:useCard{
        from = player,
        tos = {player},
        card = Fk:getCardById(id),
      }
    elseif use.card.trueName == "peach" or use.card.trueName == "analeptic" then
      room:obtainCard(player, id, true, fk.ReasonJustMove, player, saying.name)
    end
  end,
  enabled_at_play = function(self, player)
    local names = player:getViewAsCardNames(saying.name, {"slash", "jink", "peach", "analeptic"}, nil, player:getTableMark("saying-round"))
    if #names == 0 then return end
    if (table.contains(names, "slash") or table.contains(names, "jink")) and #player:getHandlyIds() > 0 then
      return true
    end
    if (table.contains(names, "peach") or table.contains(names, "analeptic")) and #player:getCardIds("e") > 0 then
      return true
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return end
    local names = player:getViewAsCardNames(saying.name, {"slash", "jink", "peach", "analeptic"}, nil, player:getTableMark("saying-round"))
    if #names == 0 then return end
    if (table.contains(names, "slash") or table.contains(names, "jink")) and #player:getHandlyIds() > 0 then
      return true
    end
    if (table.contains(names, "peach") or table.contains(names, "analeptic")) and #player:getCardIds("e") > 0 then
      return true
    end
  end,
})

return saying
