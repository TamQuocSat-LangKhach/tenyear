local guanwei = fk.CreateSkill {
  name = "guanwei",
}

Fk:loadTranslationTable{
  ["guanwei"] = "观微",
  [":guanwei"] = "每回合限一次，一名角色的出牌阶段结束时，若其于此回合内使用过至少两张牌，且这些牌花色均相同或均没有花色，你可以弃置一张牌，"..
  "令其摸两张牌并执行一个额外的出牌阶段。",

  ["#guanwei-invoke"] = "观微：你可以弃一张牌，令 %dest 摸两张牌并执行一个额外出牌阶段",

  ["$guanwei1"] = "今日宴请诸位，有要事相商。",
  ["$guanwei2"] = "天下未定，请主公以大局为重。",
}

guanwei:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(guanwei.name) and target.phase == Player.Play and
      player:usedSkillTimes(guanwei.name, Player.HistoryTurn) == 0 and not player:isNude() and not target.dead then
      local x = 0
      local suit = nil
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == target then
          if suit == nil then
            suit = use.card.suit
          elseif suit ~= use.card.suit then
            x = 0
            return true
          end
          x = x + 1
        end
      end, Player.HistoryTurn)
      return x > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = guanwei.name,
      cancelable = true,
      prompt = "#guanwei-invoke::"..target.id,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {target}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self).cards, guanwei.name, player, player)
    if not target.dead then
      target:drawCards(2, guanwei.name)
      if not target.dead then
        target:gainAnExtraPhase(Player.Play, guanwei.name)
      end
    end
  end,
})

return guanwei
