local wuyou_active = fk.CreateSkill {
  name = "wuyou&",
}

Fk:loadTranslationTable{
  ["wuyou&"] = "武佑",
  [":wuyou&"] = "出牌阶段限一次，你可以交给武关羽一张手牌，其可以从五个随机非装备牌名中选择一个并交给你一张手牌，"..
  "此牌视为其选择的牌名且无距离次数限制。",

  ["#wuyou&"] = "武佑：将一张手牌交给拥有“武佑”的角色，其可以从五个随机牌名中选择，令一张牌视为声明的牌并交给你",
}

wuyou_active:addEffect("active", {
  anim_type = "support",
  prompt = "#wuyou&",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill("wuyou") and not table.contains(player:getTableMark("wuyou-phase"), p.id)
    end)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:hasSkill("wuyou") and
      not table.contains(player:getTableMark("wuyou-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    target:broadcastSkillInvoke("wuyou")
    room:addTableMarkIfNeed(player, "wuyou-phase", player.id)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, "wuyou", nil, false, player)
    if player.dead or player:isKongcheng() or target.dead then return end
    local skill = Fk.skills["wuyou"]
    skill:onUse(room, {
      from = target,
      tos = { player },
    })
  end,
})

return wuyou_active
