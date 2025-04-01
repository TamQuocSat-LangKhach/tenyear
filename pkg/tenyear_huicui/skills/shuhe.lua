local shuhe = fk.CreateSkill {
  name = "shuhe",
}

Fk:loadTranslationTable{
  ["shuhe"] = "数合",
  [":shuhe"] = "出牌阶段限一次，你可以展示一张手牌，并获得场上与展示牌相同点数的牌，令〖列侯〗额外摸牌数+1（至多为5）。若你没有因此获得牌，"..
  "你需将展示牌交给一名其他角色",

  ["#shuhe"] = "数合：展示一张手牌，获得场上所有同点数牌，若未获得则将此牌交给一名其他角色",
  ["#shuhe-choose"] = "数合：你需将%arg交给一名其他角色",

  ["$shuhe1"] = "齐心共举，万事俱成。",
  ["$shuhe2"] = "手足协力，天下可往。",
}

shuhe:addEffect("active", {
  anim_type = "control",
  prompt = "#shuhe",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(shuhe.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if player:getMark("ty__liehou") < 5 and player:hasSkill("ty__liehou", true) then
      room:addPlayerMark(player, "ty__liehou", 1)
    end
    local number = Fk:getCardById(effect.cards[1]).number
    player:showCards(effect.cards)
    if player.dead then return end
    local cards = {}
    for _, p in ipairs(room.alive_players) do
      table.insertTable(cards, table.filter(p:getCardIds("ej"), function (id)
        return Fk:getCardById(id).number == number
      end))
    end
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, shuhe.name, nil, true, player)
    elseif #room:getOtherPlayers(player, true) > 0 and
      table.contains(player:getCardIds("h"), effect.cards[1]) then
      local to = room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(player, true),
        min_num = 1,
        max_num = 1,
        prompt = "#shuhe-choose:::"..Fk:getCardById(effect.cards[1]):toLogString(),
        skill_name = shuhe.name,
        cancelable = false,
      })[1]
      room:obtainCard(to, effect.cards, true, fk.ReasonGive, player, shuhe.name)
    end
  end,
})

return shuhe
