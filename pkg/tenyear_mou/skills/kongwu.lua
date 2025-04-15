local kongwu = fk.CreateSkill {
  name = "kongwu",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["kongwu"] = "孔武",
  [":kongwu"] = "转换技，出牌阶段限一次，你可以弃置至多体力上限张牌并选择一名其他角色：阳：弃置其至多等量的牌；阴：视为对其使用等量张【杀】。"..
  "此阶段结束时，若其手牌数和体力值均不大于你，其下回合装备区内的牌失效且摸牌阶段摸牌数-1。",

  ["#kongwu-yang"] = "孔武：你可以弃置至多%arg张牌，弃置一名其他角色至多等量的牌",
  ["#kongwu-yin"] = "孔武：你可以弃置至多%arg张牌，视为对一名其他角色使用等量张【杀】",
  ["#kongwu-discard"] = "孔武：弃置 %dest 至多%arg张牌",
  ["@@kongwu-turn"] = "孔武",

  ["$kongwu1"] = "臂有千斤力，何惧万人敌！",
  ["$kongwu2"] = "莫说兵器，取汝首级也易如反掌。",
}

kongwu:addEffect("active", {
  anim_type = "switch",
  min_card_num = 1,
  max_card_num = function (self, player)
    return player.maxHp
  end,
  target_num = 1,
  prompt = function (self, player, selected_cards, selected_targets)
    if player:getSwitchSkillState(kongwu.name, false) == fk.SwitchYang then
      return "#kongwu-yang:::"..player.maxHp
    else
      return "#kongwu-yin:::"..player.maxHp
    end
  end,
  can_use = function (self, player)
    return player:usedSkillTimes(kongwu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected < player.maxHp and not player:prohibitDiscard(to_select)
  end,
  target_filter = function (self, player, to_select, selected)
    if #selected == 0 and to_select ~= player then
      if player:getSwitchSkillState(kongwu.name, false) == fk.SwitchYang then
        return not to_select:isNude()
      else
        return true
      end
    end
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, kongwu.name, player, player)
    if player.dead then return end
    local n = #effect.cards
    room:addTableMarkIfNeed(player, "kongwu-phase", target.id)
    if player:getSwitchSkillState(kongwu.name, true) == fk.SwitchYang then
      local cards = room:askToChooseCards(player, {
        skill_name = kongwu.name,
        target = target,
        min = 1,
        max = n,
        flag = "he",
        prompt = "#kongwu-discard::"..target.id..":"..n,
      })
      room:throwCard(cards, kongwu.name, target, player)
    else
      for _ = 1, n, 1 do
        if target.dead then return end
        room:useVirtualCard("slash", nil, player, target, kongwu.name, true)
      end
    end
  end,
})

kongwu:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark("kongwu-phase") ~= 0 and
      table.find(player:getTableMark("kongwu-phase"), function (id)
        local to = player.room:getPlayerById(id)
        return not to.dead and to:getHandcardNum() <= player:getHandcardNum() and to.hp <= player.hp
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = table.filter(player:getTableMark("kongwu-phase"), function (id)
      local to = room:getPlayerById(id)
      return not to.dead and to:getHandcardNum() <= player:getHandcardNum() and to.hp <= player.hp
    end)
    tos = table.map(tos, Util.Id2PlayerMapper)
    room:sortByAction(tos)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      room:addPlayerMark(p, kongwu.name, 1)
    end
  end,
})
kongwu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(kongwu.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@kongwu-turn", player:getMark("kongwu"))
    room:setPlayerMark(player, "kongwu", 0)
  end,
})
kongwu:addEffect(fk.DrawNCards, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@kongwu-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.n = data.n - player:getMark("@@kongwu-turn")
  end,
})

kongwu:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("@@kongwu-turn") > 0 and skill:isEquipmentSkill(from)
  end,
})

return kongwu
