local gue = fk.CreateSkill {
  name = "gue"
}

Fk:loadTranslationTable{
  ['gue'] = '孤扼',
  ['#gue'] = '孤扼：你可以展示所有手牌，若【杀】【闪】总数不大于1，视为你使用或打出之',
  [':gue'] = '每名其他角色的回合内限一次，当你需要使用或打出【杀】或【闪】时，你可以：展示所有手牌，若其中【杀】和【闪】的总数小于2，视为你使用或打出之。',
  ['$gue1'] = '哀兵必胜，况吾众志成城。',
  ['$gue2'] = '扼守孤城，试问万夫谁开？',
}

gue:addEffect('viewas', {
  anim_type = "defensive",
  pattern = "slash,jink",
  prompt = "#gue",
  interaction = function()
    local names = {}
    for _, name in ipairs({"slash", "jink"}) do
      local card = Fk:cloneCard(name)
      if ((Fk.currentResponsePattern == nil and Self:canUse(card) and not Self:prohibitUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = {"slash", "jink"} }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not skill.interaction.data then return end
    local card = Fk:cloneCard(skill.interaction.data)
    card.skillName = skill.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local cards = player:getCardIds("h")
    if #cards == 0 then return end
    player:showCards(cards)
    if #table.filter(cards, function(id)
      return table.contains({"slash", "jink"}, Fk:getCardById(id).trueName)
    end) > 1 then
      return ""
    end
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player, response)
    return player:usedSkillTimes(skill.name) == 0 and table.find(Fk:currentRoom().alive_players, function (p)
      return p ~= player and p.phase ~= Player.NotActive
    end)
  end,
})

return gue
