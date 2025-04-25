local jiweic_active = fk.CreateSkill{
  name = "jiweic&",
}

Fk:loadTranslationTable{
  ["jiweic&"] = "极威",
  [":jiweic&"] = "你可以交给威曹丕一张手牌，然后其可以令你发动一次至多弃置3张牌的〖典论〗。",

  ["#jiweic&"] = "极威：将一张手牌交给威曹丕，其可以令你发动一次“典论”",
  ["#jiweic-invoke"] = "极威：是否允许 %src 发动一次“典论”？",
}

jiweic_active:addEffect("active", {
  mute = true,
  prompt = "#jiweic&",
  card_num = 1,
  target_num = 1,
  can_use = function (self, player)
    return player.kingdom == "wei" and
      table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= player and p:hasSkill("jiweic")
      end)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return to_select:hasSkill("jiweic")
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    target:broadcastSkillInvoke("jiweic")
    room:notifySkillInvoked(target, "jiweic", "support")
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, "jiweic", nil, false, player)
    if target.dead or player.dead or player:isKongcheng() then return end
    if room:askToSkillInvoke(target, {
      skill_name = "jiweic",
      prompt = "#jiweic-invoke:"..player.id,
    }) then
      room:doIndicate(target, {player})
      room:askToUseActiveSkill(player, {
        skill_name = "dianlun",
        prompt = "#dianlun",
        extra_data = {
          jiweic = true,
        }
      })
    end
  end,
})

return jiweic_active
