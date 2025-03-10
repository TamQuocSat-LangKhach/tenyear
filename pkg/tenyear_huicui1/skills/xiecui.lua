local xiecui = fk.CreateSkill {
  name = "xiecui"
}

Fk:loadTranslationTable{
  ['xiecui'] = '撷翠',
  ['#xiecui-invoke'] = '撷翠：你可以令 %src 对 %dest造成的伤害+1',
  [':xiecui'] = '当一名角色于其回合内使用牌首次造成伤害时，你可令此伤害+1。若该角色为吴势力角色，其获得此伤害牌且本回合手牌上限+1。',
  ['$xiecui1'] = '东隅既得，亦收桑榆。',
  ['$xiecui2'] = '江东多娇，锦花相簇。',
}

xiecui:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiecui.name) and target and not target.dead and target == player.room.current and data.card and
      player:usedSkillTimes(xiecui.name, Player.HistoryTurn) == 0 and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data[1].from == target and e.data[1].card
      end) == 0
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(player, {tos = {target.id}})
    return player.room:askToSkillInvoke(player, {
      skill_name = xiecui.name,
      prompt = "#xiecui-invoke:"..data.from.id..":"..data.to.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage = data.damage + 1
    if not target.dead and target.kingdom == "wu" then
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 1)
      local cost_data = event:getCostData(player)
      if room:getCardArea(data.card) == Card.Processing then
        room:moveCardTo(data.card, Card.PlayerHand, target, fk.ReasonPrey, xiecui.name)
      end
    end
  end,
})

return xiecui
