local ty__langmie = fk.CreateSkill {
  name = "ty__langmie"
}

Fk:loadTranslationTable{
  ['ty__langmie'] = '狼灭',
  ['#ty__langmie-draw'] = '狼灭：你可以摸一张牌',
  ['#ty__langmie-damage'] = '狼灭：你可以弃置一张牌，对 %dest 造成1点伤害',
  [':ty__langmie'] = '其他角色出牌阶段结束时，若其本阶段使用过至少两张相同类别的牌，你可以摸一张牌；其他角色的结束阶段，若其本回合造成过至少2点伤害，你可以弃置一张牌，对其造成1点伤害。',
  ['$ty__langmie1'] = '狼性凶残，不得不灭！',
  ['$ty__langmie2'] = '贪狼环伺，眈眈相向，灭之方可除虑。',
}

ty__langmie:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty__langmie.name) and target ~= player then
      local count = {0, 0, 0}
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        if use.from == target.id then
          if use.card.type == Card.TypeBasic then
            count[1] = count[1] + 1
          elseif use.card.type == Card.TypeTrick then
            count[2] = count[2] + 1
          elseif use.card.type == Card.TypeEquip then
            count[3] = count[3] + 1
          end
        end
      end, Player.HistoryPhase)
      return table.find(count, function(i) return i > 1 end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return player.room:askToSkillInvoke(player, {skill_name = ty__langmie.name, prompt = "#ty__langmie-draw"})
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty__langmie.name)
    if event == fk.EventPhaseEnd then
      room:notifySkillInvoked(player, ty__langmie.name, "drawcard")
      player:drawCards(1, ty__langmie.name)
    end
  end,
})

ty__langmie:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty__langmie.name) and target ~= player then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 999, function(e)
        local damage = e.data[5]
        if damage and target == damage.from then
          n = n + damage.damage
        end
      end, Player.HistoryTurn)
      return n > 1 and not player:isNude()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {min_num = 1, max_num = 1, include_equip = true, skill_name = ty__langmie.name, cancelable = true, prompt = "#ty__langmie-damage::" .. target.id})
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty__langmie.name)
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, ty__langmie.name, "offensive")
      room:doIndicate(player.id, {target.id})
      room:throwCard(event:getCostData(self), ty__langmie.name, player, player)
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = ty__langmie.name,
      }
    end
  end,
})

return ty__langmie
