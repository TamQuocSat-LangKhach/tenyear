local zhiheng = fk.CreateSkill {
  name = "tycl__zhiheng",
}

Fk:loadTranslationTable{
  ["tycl__zhiheng"] = "制衡",
  [":tycl__zhiheng"] = "出牌阶段限一次，你可以弃置任意张牌，然后摸等量的牌。若你以此法弃置了所有的手牌，额外摸一张牌。"..
  "出牌阶段对每名角色限一次，当你对其他角色造成伤害后，此技能本阶段可发动次数+1。",

  ["#tycl__zhiheng"] = "制衡：弃置任意张牌，摸等量的牌，若弃置了所有手牌额外摸一张",

  ["$tycl__zhiheng"] = "容我三思。",
}

zhiheng:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#tycl__zhiheng",
  min_card_num = 1,
  target_num = 0,
  times = function(self, player)
    return player.phase == Player.Play and
      1 + #player:getTableMark("tycl__zhiheng-phase") - player:usedSkillTimes(zhiheng.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(zhiheng.name, Player.HistoryPhase) < 1 + #player:getTableMark("tycl__zhiheng-phase")
  end,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local hand = player:getCardIds("h")
    local more = #hand > 0
    for _, id in ipairs(hand) do
      if not table.contains(effect.cards, id) then
        more = false
        break
      end
    end
    room:throwCard(effect.cards, zhiheng.name, player, player)
    if player.dead then return end
    room:drawCards(player, #effect.cards + (more and 1 or 0), zhiheng.name)
  end,
})

zhiheng:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhiheng.name) and player.phase == Player.Play and
      data.to ~= player and not table.contains(player:getTableMark("tycl__zhiheng-phase"), data.to.id)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "tycl__zhiheng-phase", data.to.id)
  end,
})

return zhiheng
