local diezhang = fk.CreateSkill {
  name = "diezhang"
}

Fk:loadTranslationTable{
  ['diezhang'] = '叠嶂',
  ['#diezhang1-invoke'] = '叠嶂：你可以弃置一张牌，视为对 %dest 使用【杀】',
  ['#diezhang2-invoke'] = '叠嶂：你可以摸一张牌，视为对 %dest 使用【杀】',
  [':diezhang'] = '转换技，你出牌阶段使用【杀】次数上限+1。阳：当你使用牌被其他角色抵消后，你可以弃置一张牌视为对其使用(一)张【杀】；阴：当你使用牌抵消其他角色使用的牌后，你可以摸(一)张牌视为对其使用一张【杀】。',
  ['$diezhang1'] = '某家这大锤，舞起来那叫一个万夫莫敌。',
  ['$diezhang2'] = '贼吕布何在？某家来取汝性命了！',
}

diezhang:addEffect(fk.CardUseFinished, {
  anim_type = "switch",
  switch_skill_name = "diezhang",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(diezhang) and data.responseToEvent and data.responseToEvent.from then
      if player:getSwitchSkillState(diezhang.name, false) == fk.SwitchYang then
        if data.responseToEvent.from == player.id and not player:isNude() then
          return target ~= player and not target.dead and not player:isProhibited(target, Fk:cloneCard("slash"))
        end
      else
        if target == player then
          local from = player.room:getPlayerById(data.responseToEvent.from)
          return from ~= player and not from.dead and not player:isProhibited(from, Fk:cloneCard("slash"))
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(diezhang.name, false) == fk.SwitchYang then
      local card = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = diezhang.name,
        cancelable = true,
        prompt = "#diezhang1-invoke::" .. target.id,
      })
      if #card > 0 then
        event:setCostData(skill, {target.id, card})
        return true
      end
    else
      if room:askToSkillInvoke(player, {
        skill_name = diezhang.name,
        prompt = "#diezhang2-invoke::" .. data.responseToEvent.from,
      }) then
        event:setCostData(skill, {data.responseToEvent.from})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(diezhang.name, true) == fk.SwitchYang then
      room:throwCard(event:getCostData(skill)[2], diezhang.name, player, player)
    else
      player:drawCards(1, diezhang.name)
    end
    local to = room:getPlayerById(event:getCostData(skill)[1])
    if not player.dead and not to.dead then
      room:useVirtualCard("slash", nil, player, to, diezhang.name, true)
    end
  end,
})

diezhang:addEffect('targetmod', {
  residue_func = function(self, player, skill, scope, card)
    if card and player:hasSkill(diezhang) and card.trueName == "slash" and scope == Player.HistoryPhase then
      return 1
    end
  end,
})

return diezhang
