local fuping = fk.CreateSkill {
  name = "fuping"
}

Fk:loadTranslationTable{
  ['fuping'] = '浮萍',
  ['#fuping-viewas'] = '发动 浮萍，将一张非基本牌当记录过的牌使用',
  ['@$fuping'] = '浮萍',
  ['#fuping_trigger'] = '浮萍',
  ['#fuping-choice'] = '是否发动 浮萍，废除一个装备栏，记录牌名【%arg】',
  [':fuping'] = '当其他角色以你为目标的基本牌或锦囊牌牌结算后，若你未记录此牌，你可以废除一个装备栏并记录此牌。你可以将一张非基本牌当记录的牌使用或打出（每种牌名每回合限一次）。若你的装备栏均已废除，你使用牌无距离限制。',
  ['$fuping1'] = '有草生清池，无根碧波上。',
  ['$fuping2'] = '愿为浮萍草，托身寄清池。',
}

-- ViewAsSkill
fuping:addEffect('viewas', {
  anim_type = "special",
  pattern = ".",
  prompt = "#fuping-viewas",
  interaction = function(self, player)
    local all_names = player:getTableMark("@$fuping")
    local names = U.getViewAsCardNames(player, fuping.name, all_names, {}, player:getTableMark("fuping-turn"))
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = fuping.name
    return card
  end,
  enabled_at_play = function(self, player)
    return #U.getViewAsCardNames(player, fuping.name, player:getTableMark("@$fuping"), {}, player:getTableMark("fuping-turn")) > 0
  end,
  enabled_at_response = function(self, player, response)
    return #U.getViewAsCardNames(player, fuping.name, player:getTableMark("@$fuping"), {}, player:getTableMark("fuping-turn")) > 0
  end,
  before_use = function(self, player, useData)
    player.room:addTableMark(player, "fuping-turn", useData.card.trueName)
  end,
})

-- TriggerSkill
fuping:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if target == player or not player:hasSkill(fuping.name) or #player:getAvailableEquipSlots() == 0 then return false end
    if data.card.type ~= Card.TypeEquip and table.contains(TargetGroup:getRealTargets(data.tos), player.id) then
      return not table.contains(player:getTableMark("@$fuping"), data.card.trueName)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"WeaponSlot", "ArmorSlot", "DefensiveRideSlot", "OffensiveRideSlot", "TreasureSlot"}
    local subtypes = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
    local choices = {}
    for i = 1, 5, 1 do
      if #player:getAvailableEquipSlots(subtypes[i]) > 0 then
        table.insert(choices, all_choices[i])
      end
    end
    table.insert(all_choices, "Cancel")
    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = fuping.name,
      prompt = "#fuping-choice:::" .. data.card.trueName,
      all_choices = all_choices
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(fuping.name)
    room:abortPlayerArea(player, {event:getCostData(self)})
    room:addTableMark(player, "@$fuping", data.card.trueName)
  end,
  can_refresh = function(self, event, target, player, data)
    return target == player and data == fuping
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@$fuping", 0)
    room:setPlayerMark(player, "fuping-turn", 0)
  end,
})

-- TargetModSkill
fuping:addEffect('targetmod', {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(fuping.name) and #player:getAvailableEquipSlots() == 0
  end,
})

return fuping
