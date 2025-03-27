local sigong = fk.CreateSkill {
  name = "sigong"
}

Fk:loadTranslationTable{
  ['sigong'] = '伺攻',
  ['#sigong-discard'] = '伺攻：你可以将手牌弃至一张，视为对 %dest 使用【杀】',
  ['#sigong-invoke'] = '伺攻：你可以视为对 %dest 使用【杀】',
  ['#sigong-draw'] = '伺攻：你可以摸一张牌，视为对 %dest 使用【杀】',
  [':sigong'] = '其他角色的回合结束时，若其本回合内使用牌被响应过，你可以将手牌调整至一张，视为对其使用一张需要X张【闪】抵消且伤害+1的【杀】（X为你以此法弃置牌数且至少为1）。若此【杀】造成伤害，此技能本轮失效。',
  ['$sigong1'] = '善守者亦善攻，不可死守。',
  ['$sigong2'] = '璋军疲敝，可伺机而攻。',
}

sigong:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) and target ~= player and
      not target.dead and not player:isProhibited(target, Fk:cloneCard("slash")) then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use.responseToEvent and use.responseToEvent.from == target.id
      end, Player.HistoryTurn)
      if #events > 0 then return true end
      events = player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
        local response = e.data[1]
        return response.responseToEvent and response.responseToEvent.from == target.id
      end, Player.HistoryTurn)
      if #events > 0 then return true end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player:getHandcardNum() > 1 then
      local n = player:getHandcardNum() - 1
      local cards = player.room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        pattern = ".|.|.|hand",
        prompt = "#sigong-discard::" .. target.id,
        cancelable = true,
        skip = true
      })
      if #cards == n then
        event:setCostData(skill, cards)
        return true
      end
    else
      local prompt = "#sigong-invoke::" .. target.id
      if player:isKongcheng() then
        prompt = "#sigong-draw::"..target.id
      end
      if player.room:askToSkillInvoke(player, {
        skill_name = skill.name,
        prompt = prompt
      }) then
        event:setCostData(skill, {})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isKongcheng() then
      player:drawCards(1, skill.name)
    else
      room:throwCard(event:getCostData(skill), skill.name, player, player)
    end
    local use = {
      from = player.id,
      tos = {{target.id}},
      card = Fk:cloneCard("slash"),
      extraUse = true,
    }
    use.card.skillName = skill.name
    if #event:getCostData(skill) > 0 then
      use.extra_data = use.extra_data or {}
      use.extra_data.sigong = #event:getCostData(skill)
    end
    use.additionalDamage = (use.additionalDamage or 0) + 1
    room:useCard(use)
    if not player.dead and use.damageDealt then
      room:invalidateSkill(player, skill.name, "-round")
    end
  end,
})

sigong:addEffect(fk.PreCardEffect, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, skill.name)
  end,
  on_refresh = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.sigong then
      data.fixedResponseTimes = data.fixedResponseTimes or {}
      data.fixedResponseTimes["jink"] = data.extra_data.sigong
    end
  end,
})

return sigong
