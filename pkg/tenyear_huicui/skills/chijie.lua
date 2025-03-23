local chijie = fk.CreateSkill {
  name = "chijie"
}

Fk:loadTranslationTable{
  ['chijie'] = '持节',
  ['#chijie-nullify'] = '持节：你可以令 %arg 在接下来的结算中对其他角色无效',
  ['#chijie-give'] = '持节：你可以获得此 %arg',
  [':chijie'] = '每回合每项各限一次，<br>①当其他角色使用牌对你生效时，你可以令此牌在接下来的结算中对其他角色无效；<br>②当其他角色使用牌结算结束后，若你是目标之一且此牌没有造成过伤害，你可以获得之。',
  ['$chijie1'] = '持节阻战，奉帝赐诏。',
  ['$chijie2'] = '此战不在急，请仲达明了。',
}

chijie:addEffect(fk.CardEffecting, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chijie.name) and data.from ~= player.id and target == player and player:getMark("chijie_a-turn") == 0
      and data.card.sub_type ~= Card.SubtypeDelayedTrick and data.tos and #TargetGroup:getRealTargets(data.tos) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:askToSkillInvoke(player, {
      skill_name = chijie.name,
      prompt = "#chijie-nullify:::" .. data.card.name
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "chijie_a-turn")
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e and e.data[1] then
      local use = e.data[1]
      local list = use.nullifiedTargets or {}
      for _, p in ipairs(room:getOtherPlayers(player)) do
        table.insertIfNeed(list, p.id)
      end
      use.nullifiedTargets = list
    end
  end,
})

chijie:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(chijie.name) and not data.damageDealt and player:getMark("chijie_b-turn") == 0 and data.tos and
      table.contains(TargetGroup:getRealTargets(data.tos), player.id) then
      local cardList = data.card:isVirtual() and data.card.subcards or {data.card.id}
      return table.find(cardList, function(id) return not player.room:getCardOwner(id) end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:askToSkillInvoke(player, {
      skill_name = chijie.name,
      prompt = "#chijie-give:::" .. data.card.name
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "chijie_b-turn")
    local cardList = data.card:isVirtual() and data.card.subcards or {data.card.id}
    local cards = table.filter(cardList, function(id) return not room:getCardOwner(id) end)
    if #cards == 0 then return end
    room:obtainCard(player, cards, true, fk.ReasonJustMove)
  end,
})

return chijie
