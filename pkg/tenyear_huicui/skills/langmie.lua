local langmie = fk.CreateSkill {
  name = "ty__langmie",
}

Fk:loadTranslationTable{
  ["ty__langmie"] = "狼灭",
  [":ty__langmie"] = "其他角色出牌阶段结束时，若其本阶段使用过至少两张相同类别的牌，你可以摸一张牌；其他角色的结束阶段，若其本回合造成过"..
  "至少2点伤害，你可以弃置一张牌，对其造成1点伤害。",

  ["#ty__langmie-draw"] = "狼灭：你可以摸一张牌",
  ["#ty__langmie-damage"] = "狼灭：你可以弃置一张牌，对 %dest 造成1点伤害",

  ["$ty__langmie1"] = "狼性凶残，不得不灭！",
  ["$ty__langmie2"] = "贪狼环伺，眈眈相向，灭之方可除虑。",
}

langmie:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(langmie.name) and target ~= player and target.phase == Player.Play then
      local count = {}
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        if use.from == target then
          count[use.card.type] = (count[use.card.type] or 0) + 1
        end
      end, Player.HistoryPhase)
      if next(count) then
        for _, v in pairs(count) do
          if v > 1 then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = langmie.name,
      prompt = "#ty__langmie-draw",
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, langmie.name)
  end,
})

langmie:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(langmie.name) and target ~= player and target.phase == Player.Finish and
      not target.dead and not player:isNude() then
      local n = 0
      player.room.logic:getActualDamageEvents(1, function(e)
        if e.data.from == target then
          n = n + e.data.damage
        end
      end, Player.HistoryTurn)
      return n > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = langmie.name,
      cancelable = true,
      prompt = "#ty__langmie-damage::"..target.id,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, langmie.name, player, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = langmie.name,
      }
    end
  end,
})

return langmie
