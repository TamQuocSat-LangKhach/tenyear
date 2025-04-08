local sigong = fk.CreateSkill {
  name = "sigong",
}

Fk:loadTranslationTable{
  ["sigong"] = "伺攻",
  [":sigong"] = "其他角色的回合结束时，若其本回合内使用牌被响应过，你可以将手牌调整至一张，视为对其使用一张需要X张【闪】抵消"..
  "且伤害+1的【杀】（X为你以此法弃置牌数且至少为1）。若此【杀】造成伤害，此技能本轮失效。",

  ["#sigong-discard"] = "伺攻：你可以将手牌弃至一张，视为对 %dest 使用【杀】",
  ["#sigong-invoke"] = "伺攻：你可以视为对 %dest 使用【杀】",
  ["#sigong-draw"] = "伺攻：你可以摸一张牌，视为对 %dest 使用【杀】",

  ["$sigong1"] = "善守者亦善攻，不可死守。",
  ["$sigong2"] = "璋军疲敝，可伺机而攻。",
}

sigong:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(sigong.name) and target ~= player and
      not target.dead and not player:isProhibited(target, Fk:cloneCard("slash")) then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data
        return use.responseToEvent and use.responseToEvent.from == target
      end, Player.HistoryTurn)
      if #events > 0 then return true end
      events = player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
        local response = e.data
        return response.responseToEvent and response.responseToEvent.from == target
      end, Player.HistoryTurn)
      if #events > 0 then return true end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() > 1 then
      local n = player:getHandcardNum() - 1
      local cards = room:askToDiscard(player, {
        skill_name = sigong.name,
        min_num = n,
        max_num = n,
        include_equip = false,
        prompt = "#sigong-discard::" .. target.id,
        cancelable = true,
        skip = true,
      })
      if #cards == n then
        event:setCostData(self, {cards = cards})
        return true
      end
    else
      local prompt = "#sigong-invoke::"..target.id
      if player:isKongcheng() then
        prompt = "#sigong-draw::"..target.id
      end
      if player.room:askToSkillInvoke(player, {
        skill_name = sigong.name,
        prompt = prompt,
      }) then
        event:setCostData(self, {cards = {}})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    if player:isKongcheng() then
      player:drawCards(1, sigong.name)
    elseif #cards > 0 then
      room:throwCard(cards, sigong.name, player, player)
    end
    if target.dead then return end
    local use = {
      from = player,
      tos = {target},
      card = Fk:cloneCard("slash"),
      extraUse = true,
    }
    use.card.skillName = sigong.name
    if #cards > 0 then
      use.extra_data = use.extra_data or {}
      use.extra_data.sigong = #cards
    end
    use.additionalDamage = (use.additionalDamage or 0) + 1
    room:useCard(use)
    if not player.dead and use.damageDealt then
      room:invalidateSkill(player, sigong.name, "-round")
    end
  end,
})

sigong:addEffect(fk.PreCardEffect, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, sigong.name) and
      data.extra_data and data.extra_data.sigong
  end,
  on_refresh = function(self, event, target, player, data)
    data.fixedResponseTimes = data.extra_data.sigong
  end,
})

return sigong
