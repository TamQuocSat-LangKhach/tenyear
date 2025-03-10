local tycl__zhiheng = fk.CreateSkill {
  name = "tycl__zhiheng"
}

Fk:loadTranslationTable{
  ['tycl__zhiheng'] = '制衡',
  ['@tycl__zhiheng-phase'] = '制衡',
  [':tycl__zhiheng'] = '出牌阶段限一次，你可以弃置任意张牌，然后摸等量的牌。若你以此法弃置了所有的手牌，额外摸1张牌。出牌阶段对每名角色限一次，当你对其他角色造成伤害后，此技能本阶段可发动次数+1。',
  ['$tycl__zhiheng'] = '容我三思',
}

tycl__zhiheng:addEffect('active', {
  anim_type = "drawcard",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(tycl__zhiheng.name, Player.HistoryPhase) < 1 + player:getMark("@tycl__zhiheng-phase")
  end,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local hand = player:getCardIds(Player.Hand)
    local more = #hand > 0
    for _, id in ipairs(hand) do
      if not table.contains(effect.cards, id) then
        more = false
        break
      end
    end
    room:throwCard(effect.cards, tycl__zhiheng.name, player, player)
    if player.dead then return end
    room:drawCards(player, #effect.cards + (more and 1 or 0), tycl__zhiheng.name)
  end,
})

tycl__zhiheng:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(tycl__zhiheng) and player.phase == Player.Play and data.to ~= player.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("tycl__zhiheng_record-phase")
    if not mark then mark = {} end
    if not table.contains(mark, data.to.id) then
      table.insert(mark, data.to.id)
      room:setPlayerMark(player, "tycl__zhiheng_record-phase", mark)
      room:addPlayerMark(player, "@tycl__zhiheng-phase", 1)
    end
  end,
})

return tycl__zhiheng
