local aoshi_active = fk.CreateSkill {
  name = "aoshi&"
}

Fk:loadTranslationTable{
  ["aoshi&"] = "傲势",
  [":aoshi&"] = "出牌阶段限一次，你可将一张手牌交给星袁绍，然后其可以发动一次〖纵势〗。",

  ["#aoshi&"] = "傲势：将一张手牌交给一名拥有“傲势”的角色，其可以发动一次“纵势”",
}

aoshi_active:addEffect("active", {
  anim_type = "support",
  prompt = "#aoshi&",
  mute = true,
  can_use = function(self, player)
    if player.kingdom ~= "qun" then return end
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill("aoshi") and not table.contains(player:getTableMark("aoshi_sources-phase"), p.id)
    end)
  end,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and
      to_select:hasSkill("aoshi") and
      not table.contains(player:getTableMark("aoshi_sources-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:notifySkillInvoked(player, "aoshi")
    target:broadcastSkillInvoke("aoshi")
    room:addTableMarkIfNeed(player, "aoshi_sources-phase", target.id)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, "aoshi", nil, false, player)
    if target.dead then return end
    room:askToUseActiveSkill(target, {
      skill_name = "zongshiy",
      prompt = "#zongshiy",
      cancelable = true,
    })
  end,
})

return aoshi_active
