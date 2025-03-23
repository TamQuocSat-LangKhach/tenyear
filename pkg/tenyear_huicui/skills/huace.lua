local huace = fk.CreateSkill {
  name = "huace"
}

Fk:loadTranslationTable{
  ['huace'] = '画策',
  ['#huace-active'] = '发动 画策，将一张手牌当上一轮没有角色使用过的普通锦囊牌使用',
  [':huace'] = '出牌阶段限一次，你可以将一张手牌当上一轮没有角色使用过的普通锦囊牌使用。',
  ['$huace1'] = '筹画所料，无有不中。',
  ['$huace2'] = '献策破敌，所谋皆应。',
}

huace:addEffect('viewas', {
  prompt = "#huace-active",
  interaction = function()
    local all_names = U.getAllCardNames("t")
    local names = U.getViewAsCardNames(Self, "zhaowen", all_names, {}, Self:getTableMark(huace.name .. "2"))
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(huace.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not skill.interaction.data then return end
    local card = Fk:cloneCard(skill.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = huace.name
    return card
  end,
})

huace:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return data.card:isCommonTrick()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark(huace.name .. "1")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, data.card.trueName)
    room:setPlayerMark(player, huace.name .. "1", mark)
  end,
})

huace:addEffect(fk.RoundStart, {
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, huace.name .. "2", player:getMark(huace.name .. "1"))
    room:setPlayerMark(player, huace.name .. "1", 0)
  end,
})

return huace
