local fengying = fk.CreateSkill {
  name = "fengyingd",
}

Fk:loadTranslationTable{
  ["fengyingd"] = "风影",
  [":fengyingd"] = "一名角色的回合开始时，记录弃牌堆中的黑色基本牌和黑色普通锦囊牌牌名。你可以将一张点数不大于“绞”标记数的手牌"..
  "当一张记录的本回合未以此法使用过的牌使用（无距离次数限制）。",

  ["#fengyingd"] = "风影：将一张点数不大于“绞”标记数的手牌当一张记录的牌使用",
  ["@$fengyingd-turn"] = "风影",

  ["$fengyingd1"] = "可怜东篱寒累树，孤影落秋风。",
  ["$fengyingd2"] = "西风落，西风落，宫墙不堪破。",
}

fengying:addEffect("viewas", {
  anim_type = "special",
  pattern = ".",
  prompt = "#fengying",
  interaction = function(self, player)
    local all_names = player:getTableMark("@$fengyingd-turn")
    local names = player:getViewAsCardNames(fengying.name, all_names, nil, player:getTableMark("@$fengying-turn"),
      {bypass_distances = true, bypass_times = true})
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).number <= player:getMark("@dongguiren_jiao") and
      table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = fengying.name
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    player.room:addTableMark(player, "@$fengyingd-turn", use.card.name)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@dongguiren_jiao") > 0 and
      #player:getViewAsCardNames(fengying.name, player:getTableMark("@$fengyingd-turn"), nil, player:getTableMark("@$fengying-turn"),
        {bypass_distances = true, bypass_times = true}) > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:getMark("@dongguiren_jiao") > 0 and
    #player:getViewAsCardNames(fengying.name, player:getTableMark("@$fengyingd-turn"), nil, player:getTableMark("@$fengying-turn"),
      {bypass_distances = true, bypass_times = true}) > 0
  end,
})

fengying:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(fengying.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(room.discard_pile) do
      local card = Fk:getCardById(id)
      if card.color == Card.Black and (card.type == Card.TypeBasic or card:isCommonTrick()) then
        table.insertIfNeed(names, card.name)
      end
    end
    room:setPlayerMark(player, "@$fengyingd-turn", #names > 0 and names or 0)
  end,
})

fengying:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@$fengyingd-turn", 0)
end)

fengying:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, fengying.name)
  end,
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, fengying.name)
  end,
})

return fengying
