local fengying = fk.CreateSkill { name = "fengying" }

Fk:loadTranslationTable{
  ['fengying'] = '风影',
  ['#fengying'] = '发动风影，将一张点数不大于绞标记数的手牌当一张记录的牌使用',
  ['@$fengying'] = '风影',
  ['@dongguiren_jiao'] = '绞',
  ['#fengying_trigger'] = '风影',
  [':fengying'] = '一名角色的回合开始时，你记录弃牌堆中的黑色基本牌和黑色普通锦囊牌牌名。你可以将一张点数不大于“绞”标记数的手牌当一张记录的本回合未以此法使用过的牌使用（无距离和次数限制）。',
  ['$fengying1'] = '可怜东篱寒累树，孤影落秋风。',
  ['$fengying2'] = '西风落，西风落，宫墙不堪破。',
}

-- ViewAsSkill部分
fengying:addEffect('viewas', {
  anim_type = "special",
  pattern = ".",
  prompt = "#fengying",
  interaction = function(self)
    local all_names, names = self.player:getTableMark("@$fengying"), {}
    for _, name in ipairs(all_names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = "fengying"
      if ((Fk.currentResponsePattern == nil and to_use.skill:canUse(self.player, to_use) and not self.player:prohibitUse(to_use)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
        table.insertIfNeed(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).number <= self.player:getMark("@dongguiren_jiao") and
      Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = fengying.name
    return card
  end,
  enabled_at_play = function(self, player)
    local names = player:getMark("@$fengying")
    if player:getMark("@dongguiren_jiao") == 0 or type(names) ~= "table" then return false end
    for _, name in ipairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = fengying.name
      if to_use.skill:canUse(player, to_use) and not player:prohibitUse(to_use) then
        return true
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    local names = player:getMark("@$fengying")
    if player:getMark("@dongguiren_jiao") == 0 or type(names) ~= "table" then return false end
    for _, name in ipairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = fengying.name
      if (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use)) then
        return true
      end
    end
  end,
  before_use = function(self, player, useData)
    useData.extraUse = true
    local names = player:getTableMark("@$fengying")
    if table.removeOne(names, useData.card.name) then
      player.room:setPlayerMark(player, "@$fengying", names)
    end
  end,
  on_lose = function (self, player)
    player.room:setPlayerMark(player, "@$fengying", 0)
  end,
})

-- TriggerSkill部分
fengying:addEffect(fk.TurnStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fengying.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(room.discard_pile) do
      local card = Fk:getCardById(id)
      if card.color == Card.Black and (card.type == Card.TypeBasic or card:isCommonTrick()) then
        table.insertIfNeed(names, card.name)
      end
    end
    room:setPlayerMark(player, "@$fengying", #names > 0 and names or 0)
  end,
})

-- TargetModSkill部分
fengying:addEffect('targetmod', {
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, fengying.name)
  end,
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, fengying.name)
  end,
})

return fengying
