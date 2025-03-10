local shoutan = fk.CreateSkill {
  name = "shoutan"
}

Fk:loadTranslationTable{
  ['shoutan'] = '手谈',
  ['#shoutan-active'] = '发动 手谈，%arg将此技能转换为%arg2状态',
  ['shoutan_yang'] = '弃置一张非黑色手牌，',
  ['shoutan_yin'] = '弃置一张黑色手牌，',
  [':shoutan'] = '转换技，出牌阶段限一次，你可以弃置一张：阳：非黑色手牌；阴：黑色手牌。',
  ['$shoutan1'] = '对弈博雅，落子珠玑胜无声。',
  ['$shoutan2'] = '弈者无言，手执黑白谈古今。',
}

shoutan:addEffect('active', {
  anim_type = "switch",
  switch_skill_name = "shoutan",
  prompt = function(self, player)
    local prompt = "#shoutan-active:::"
    if player:getSwitchSkillState(shoutan.name, false) == fk.SwitchYang then
      if not player:hasSkill(yaoyi) then
        prompt = prompt .. "shoutan_yang"
      end
      prompt = prompt .. ":yin"
    else
      if not player:hasSkill(yaoyi) then
        prompt = prompt .. "shoutan_yin"
      end
      prompt = prompt .. ":yang"
    end
    return prompt
  end,
  card_num = function(self, player)
    if player:hasSkill(yaoyi) then
      return 0
    else
      return 1
    end
  end,
  target_num = 0,
  can_use = function(self, player)
    if player:hasSkill(yaoyi) then
      return player:getMark("shoutan_prohibit-phase") == 0
    else
      return player:usedSkillTimes(shoutan.name, Player.HistoryPhase) == 0
    end
  end,
  card_filter = function(self, player, to_select, selected)
    if player:hasSkill(yaoyi) then
      return false
    elseif #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip then
      local card = Fk:getCardById(to_select)
      return not player:prohibitDiscard(card) and (card.color == Card.Black) == (player:getSwitchSkillState(shoutan.name, false) == fk.SwitchYin)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, shoutan.name, player, player)
  end,
})

shoutan:addEffect(fk.StartPlayCard, {
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("shoutan-phase") < player:usedSkillTimes(shoutan.name, Player.HistoryPhase) then
      room:setPlayerMark(player, "shoutan-phase", player:usedSkillTimes(shoutan.name, Player.HistoryPhase))
      room:setPlayerMark(player, "shoutan_prohibit-phase", 1)
    else
      room:setPlayerMark(player, "shoutan_prohibit-phase", 0)
    end
  end,
})

return shoutan
