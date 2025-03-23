local shizong = fk.CreateSkill {
  name = "shizong"
}

Fk:loadTranslationTable{
  ['shizong'] = '恃纵',
  ['#shizong'] = '恃纵：你可以视为使用一张基本牌',
  ['shizong_active'] = '恃纵',
  ['#shizong-give'] = '恃纵：交给一名其他角色%arg张牌',
  ['#shizong-put'] = '恃纵：你可以将一张牌置于牌堆底，视为 %src 使用【%arg】',
  [':shizong'] = '当你需要使用一张基本牌时，你可交给一名其他角色X张牌（X为此技能本回合发动次数），然后其可将一张牌置于牌堆底，视为你使用之。若其不为当前回合角色，此技能本回合失效。',
  ['$shizong1'] = '成济、王经已死，独我安享富贵。',
  ['$shizong2'] = '吾乃司马公心腹，顺我者生！'
}

shizong:addEffect('viewas', {
  pattern = ".|.|.|.|.|basic",
  prompt = "#shizong",
  interaction = function()
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, "shizong", all_names)
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  before_use = function (self, player, use)
    local room = player.room
    -- please fix askForChooseCardsAndPlayers
    local _, dat = room:askToUseActiveSkill(player, {
      skill_name = "shizong_active",
      prompt = "#shizong-give:::"..player:usedSkillTimes(shizong.name, Player.HistoryTurn),
      cancelable = false,
    })
    if dat then
      local to = room:getPlayerById(dat.targets[1])
      if to ~= room.current then
        room:invalidateSkill(player, shizong.name, "-turn")
      end
      room:moveCardTo(dat.cards, Card.PlayerHand, to, fk.ReasonGive, shizong.name, nil, false, player.id)
      if not to.dead and not to:isNude() then
        local card = room:askToCards(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = "shizong",
          cancelable = true,
          pattern = ".",
          prompt = "#shizong-put:"..player.id.."::"..use.card.name
        })
        if #card > 0 then
          room:moveCards({
            ids = card,
            from = to.id,
            toArea = Card.DrawPile,
            moveReason = fk.ReasonJustMove,
            skillName = "shizong",
            drawPilePosition = -1,
          })
          return
        end
      end
    end
    return shizong.name
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = shizong.name
    return card
  end,
  enabled_at_play = function(self, player)
    return #player:getCardIds("he") > player:usedSkillTimes(shizong.name, Player.HistoryTurn)
  end,
  enabled_at_response = function(self, player, response)
    return not response and #player:getCardIds("he") > player:usedSkillTimes(shizong.name, Player.HistoryTurn)
  end,
})

return shizong
