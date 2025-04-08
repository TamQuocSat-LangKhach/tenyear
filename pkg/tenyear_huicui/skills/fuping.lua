local fuping = fk.CreateSkill {
  name = "fuping",
}

Fk:loadTranslationTable{
  ["fuping"] = "浮萍",
  [":fuping"] = "当其他角色以你为目标的基本牌或锦囊牌结算后，若你未记录此牌，你可以废除一个装备栏并记录此牌。"..
  "你可以将一张非基本牌当记录的牌使用或打出（每种牌名每回合限一次）。若你的装备栏均已废除，你使用牌无距离限制。",

  ["#fuping"] = "浮萍：将一张非基本牌当记录过的牌使用",
  ["@$fuping"] = "浮萍",
  ["#fuping-choice"] = "浮萍：是否废除一个装备栏，记录牌名【%arg】？",

  ["$fuping1"] = "有草生清池，无根碧波上。",
  ["$fuping2"] = "愿为浮萍草，托身寄清池。",
}

local U = require "packages/utility/utility"

fuping:addEffect("viewas", {
  anim_type = "special",
  pattern = ".",
  prompt = "#fuping",
  interaction = function(self, player)
    local all_names = player:getTableMark("@$fuping")
    local names = player:getViewAsCardNames(fuping.name, all_names, nil, player:getTableMark("fuping-turn"))
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = fuping.name
    return card
  end,
  before_use = function(self, player, useData)
    player.room:addTableMark(player, "fuping-turn", useData.card.trueName)
  end,
  enabled_at_play = function(self, player)
    return #player:getViewAsCardNames(fuping.name, player:getTableMark("@$fuping"), nil, player:getTableMark("fuping-turn")) > 0
  end,
  enabled_at_response = function(self, player, response)
    return #player:getViewAsCardNames(fuping.name, player:getTableMark("@$fuping"), nil, player:getTableMark("fuping-turn")) > 0
  end,
})

fuping:addEffect(fk.CardUseFinished, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(fuping.name) and #player:getAvailableEquipSlots() > 0 and
      data.card.type ~= Card.TypeEquip and table.contains(data.tos, player) and
      not table.contains(player:getTableMark("@$fuping"), data.card.trueName)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = table.simpleClone(player:getAvailableEquipSlots())
    table.insert(choices, "Cancel")
    local all_choices = {
      "WeaponSlot",
      "ArmorSlot",
      "DefensiveRideSlot",
      "OffensiveRideSlot",
      "TreasureSlot",
      "Cancel",
    }
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = fuping.name,
      prompt = "#fuping-choice:::" .. data.card.trueName,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:abortPlayerArea(player, {event:getCostData(self).choice})
    room:addTableMark(player, "@$fuping", data.card.trueName)
  end,
})

fuping:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(fuping.name) and card and #player:getAvailableEquipSlots() == 0
  end,
})

fuping:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@$fuping", 0)
  room:setPlayerMark(player, "fuping-turn", 0)
end)

return fuping
