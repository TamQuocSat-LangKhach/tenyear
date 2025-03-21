local kongwu = fk.CreateSkill {
  name = "kongwu"
}

Fk:loadTranslationTable{
  ['kongwu'] = '孔武',
  ['#kongwu-yang'] = '孔武：你可以弃置至多%arg张牌，弃置一名其他角色至多等量的牌',
  ['#kongwu-yin'] = '孔武：你可以弃置至多%arg张牌，视为对一名其他角色使用等量张【杀】',
  ['#kongwu-discard'] = '孔武：弃置 %dest 至多%arg张牌',
  ['@@kongwu-turn'] = '孔武',
  [':kongwu'] = '转换技，出牌阶段限一次，你可以弃置至多体力上限张牌并选择一名其他角色：阳：弃置其至多等量的牌；阴：视为对其使用等量张【杀】。此阶段结束时，若其手牌数和体力值均不大于你，其下回合装备区内的牌失效且摸牌阶段摸牌数-1。',
  ['$kongwu1'] = '臂有千斤力，何惧万人敌！',
  ['$kongwu2'] = '莫说兵器，取汝首级也易如反掌。',
}

kongwu:addEffect("active", {
  anim_type = "switch",
  switch_skill_name = kongwu.name,
  min_card_num = 1,
  max_card_num = function (player)
    return player.maxHp
  end,
  target_num = 1,
  prompt = function (_, player, selected_cards, selected_targets)
    if player:getSwitchSkillState(kongwu.name, false) == fk.SwitchYang then
      return "#kongwu-yang:::"..player.maxHp
    else
      return "#kongwu-yin:::"..player.maxHp
    end
  end,
  can_use = function (_, player)
    return player:usedSkillTimes(kongwu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (_, player, to_select, selected)
    return #selected < player.maxHp and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function (_, player, to_select, selected)
    if #selected == 0 and to_select ~= player.id then
      if player:getSwitchSkillState(kongwu.name, false) == fk.SwitchYang then
        return not Fk:currentRoom():getPlayerById(to_select):isNude()
      else
        return true
      end
    end
  end,
  on_use = function (_, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, kongwu.name, player, player)
    if player.dead then return end
    local n = #effect.cards
    room:addTableMarkIfNeed(player, "kongwu-phase", target.id)
    if player:getSwitchSkillState(kongwu.name, true) == fk.SwitchYang then
      local cards = room:askToChooseCards(player, {
        min_card_num = 1,
        max_card_num = n,
        target = target,
        flag = "he",
        skill_name = kongwu.name,
        prompt = "#kongwu-discard::"..target.id..":"..n
      })
      room:throwCard(cards, kongwu.name, target, player)
    else
      for i = 1, n, 1 do
        if target.dead then return end
        room:useVirtualCard("slash", nil, player, target, kongwu.name, true)
      end
    end
  end,
})

kongwu:addEffect(fk.EventPhaseEnd, {
  mute = true,
  can_trigger = function(_, event, target, player)
    return target == player and player.phase == Player.Play and player:getMark("kongwu-phase") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("kongwu-phase")
    for _, id in ipairs(mark) do
      local to = room:getPlayerById(id)
      if not to.dead and to:getHandcardNum() <= player:getHandcardNum() and to.hp <= player.hp then
        player:broadcastSkillInvoke(kongwu.name)
        room:notifySkillInvoked(player, kongwu.name, "control")
        room:doIndicate(player.id, {to.id})
        room:addPlayerMark(to, "kongwu", 1)
      end
    end
  end,
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.TurnStart then
        return player:getMark("kongwu") > 0
      else
        return player:getMark("@@kongwu-turn") > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:setPlayerMark(player, "@@kongwu-turn", player:getMark("kongwu"))
      room:setPlayerMark(player, "kongwu", 0)
    else
      data.n = data.n - player:getMark("@@kongwu-turn")
    end
  end,
})

kongwu:addEffect("#kongwu_invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("@@kongwu-turn") > 0 and skill:isEquipmentSkill(from)
  end
})

return kongwu
