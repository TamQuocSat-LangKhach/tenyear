local qinguo = fk.CreateSkill {
  name = "qinguo"
}

Fk:loadTranslationTable{
  ['qinguo'] = '勤国',
  ['qinguo_viewas'] = '勤国',
  ['#qinguo-ask'] = '勤国：你可以视为使用一张【杀】',
  [':qinguo'] = '当你于回合内使用装备牌结算结束后，你可视为使用【杀】；当你的装备区里的牌数变化后，若你装备区里的牌数与你的体力值相等，你回复1点体力。',
  ['$qinguo1'] = '为国勤事，体素精勤。',
  ['$qinguo2'] = '忠勤为国，通达治体。',
}

qinguo:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(qinguo.name) and player.phase ~= Player.NotActive then
      return target == player and data.card.type == Card.TypeEquip
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "qinguo_viewas",
      prompt = "#qinguo-ask",
      cancelable = true
    })
    if success then
      event:setCostData(self, dat)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(qinguo.name)
    room:notifySkillInvoked(player, qinguo.name, "offensive")
    local card = Fk.skills["qinguo_viewas"]:viewAs(event:getCostData(self).cards)
    room:useCard{
      from = player.id,
      tos = table.map(event:getCostData(self).targets, function(id) return {id} end),
      card = card,
      extraUse = true,
    }
  end,
})

qinguo:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(qinguo.name) and player.phase ~= Player.NotActive then
      local equipnum = #player:getCardIds("e")
      for _, move in ipairs(data) do
        for _, info in ipairs(move.moveInfo) do
          if move.from == player.id and info.fromArea == Card.PlayerEquip then
            equipnum = equipnum + 1
          elseif move.to == player.id and move.toArea == Card.PlayerEquip then
            equipnum = equipnum - 1
          end
        end
      end
      return #player:getCardIds("e") ~= equipnum and #player:getCardIds("e") == player.hp and player:isWounded()
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(qinguo.name)
    room:notifySkillInvoked(player, qinguo.name, "support")
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = qinguo.name,
    }
  end,
})

qinguo:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "qinguo")
  end,
})

return qinguo
