local shizong = fk.CreateSkill {
  name = "shizong",
}

Fk:loadTranslationTable{
  ["shizong"] = "恃纵",
  [":shizong"] = "当你需要使用一张基本牌时，你可以交给一名其他角色X张牌（X为此技能本回合发动次数），然后其可以将一张牌置于牌堆底，视为你使用之。"..
  "若其不为当前回合角色，此技能本回合失效。",

  ["#shizong"] = "恃纵：交给一名角色 %arg 张牌，视为使用一张基本牌（先选择使用的牌名和目标，然后交出牌）",
  ["#shizong-give"] = "恃纵：交给一名其他角色%arg张牌",
  ["#shizong-put"] = "恃纵：你可以将一张牌置于牌堆底，视为 %src 使用【%arg】",

  ["$shizong1"] = "成济、王经已死，独我安享富贵。",
  ["$shizong2"] = "吾乃司马公心腹，顺我者生！"
}

local U = require "packages/utility/utility"

shizong:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, player)
    return "#shizong:::"..(player:usedSkillTimes(shizong.name, Player.HistoryTurn) + 1)
  end,
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(shizong.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  before_use = function (self, player, use)
    local room = player.room
    local n = player:usedSkillTimes(shizong.name, Player.HistoryTurn)
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = n,
      max_card_num = n,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = shizong.name,
      prompt = "#shizong-give:::"..n,
      cancelable = false,
    })
    to = to[1]
    if to ~= room.current then
      room:invalidateSkill(player, shizong.name, "-turn")
    end
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, shizong.name, nil, false, player)
    if not to.dead and not to:isNude() then
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = shizong.name,
        prompt = "#shizong-put:"..player.id.."::"..use.card.name,
        cancelable = true,
      })
      if #card > 0 then
        room:moveCards({
          ids = card,
          from = to,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skill_name = shizong.name,
          drawPilePosition = -1,
        })
      else
        return shizong.name
      end
    else
      return shizong.name
    end
  end,
  view_as = function(self, player, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = shizong.name
    return card
  end,
  enabled_at_play = function(self, player)
    return #player:getCardIds("he") > player:usedSkillTimes(shizong.name, Player.HistoryTurn) and
      #Fk:currentRoom().alive_players > 1
  end,
  enabled_at_response = function(self, player, response)
    return not response and #player:getCardIds("he") > player:usedSkillTimes(shizong.name, Player.HistoryTurn) and
      #Fk:currentRoom().alive_players > 1
  end,
})

return shizong
