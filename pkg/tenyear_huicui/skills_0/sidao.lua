local sidao = fk.CreateSkill {
  name = "sidao"
}

Fk:loadTranslationTable{
  ['sidao'] = '伺盗',
  ['sidao_vs'] = '伺盗',
  ['#sidao-cost'] = '伺盗：你可将一张手牌当【顺手牵羊】对其中一名角色使用',
  [':sidao'] = '每阶段限一次，当你于出牌阶段内使用的牌结算结束后，若此牌与你此阶段内使用的上一张牌有相同的目标角色，你可以将一张手牌当【顺手牵羊】对其中一名不为你的角色使用。',
  ['$sidao1'] = '连发伺动，顺手可得。',
  ['$sidao2'] = '伺机而动，此地可窃。',
}

sidao:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(sidao.name) and player.phase == Player.Play and not player:isKongcheng() and
      player:usedSkillTimes(sidao.name, Player.HistoryPhase) == 0 then
      local tos = TargetGroup:getRealTargets(data.tos)
      table.removeOne(tos, player.id)
      if #tos == 0 then return false end
      local use_event = player.room.logic:getCurrentEvent()
      local turn_e = use_event:findParent(GameEvent.Phase)
      if not turn_e then return false end
      local end_id = turn_e.id
      local last_e = player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        return e.id < use_event.id and e.data[1].from == target.id
      end, end_id)
      if #last_e > 0 then
        local last_use = last_e[1].data[1]
        local avail_tos = table.filter(TargetGroup:getRealTargets(last_use.tos), function (id)
          return table.contains(tos, id)
        end)
        if #avail_tos > 0 then
          event:setCostData(self, avail_tos)
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local _,dat = player.room:askToUseActiveSkill(player, {
      skill_name = "sidao_vs",
      prompt = "#sidao-cost",
      cancelable = true,
      extra_data = { sidao_tos = event:getCostData(self) },
      no_indicate = true
    })
    if dat then
      event:setCostData(self, { tos = dat.targets, cards = dat.cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost_data = event:getCostData(self)
    player.room:useVirtualCard("snatch", cost_data.cards, player, player.room:getPlayerById(cost_data.tos[1]), sidao.name)
  end,
})

return sidao
