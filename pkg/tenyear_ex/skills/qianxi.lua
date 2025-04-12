local qianxi = fk.CreateSkill {
  name = "ty_ex__qianxi",
}

Fk:loadTranslationTable{
  ["ty_ex__qianxi"] = "潜袭",
  [":ty_ex__qianxi"] = "准备阶段，你可以摸一张牌并弃置一张牌，然后选择一名距离为1的其他角色，本回合：其不能使用或打出与你弃置的牌"..
  "颜色相同的手牌；你无视其装备区里与你弃置的牌颜色相同的防具；该角色回复体力时，你摸两张牌。",

  ["#ty_ex__qianxi-choose"] = "潜袭：选择距离1的一名角色，本回合其不能使用或打出此颜色手牌，你无视其此颜色的防具",
  ["@@ty_ex__qianxi-turn"] = "潜袭",

  ["$ty_ex__qianxi1"] = "暗影深处，袭敌斩首！",
  ["$ty_ex__qianxi2"] = "哼，出不了牌了吧？",
}

qianxi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qianxi.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, qianxi.name)
    if player.dead then return end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = qianxi.name,
      cancelable = false,
      skip = true,
    })
    if #card == 0 then return end
    local color = Fk:getCardById(card[1]):getColorString()
    room:throwCard(card, qianxi.name, player, player)
    if player.dead then return end
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:distanceTo(p) == 1
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__qianxi-choose",
      skill_name = qianxi.name,
      cancelable = false,
    })[1]
    room:addTableMarkIfNeed(to, "@@ty_ex__qianxi-turn", color)
    local mark = player:getTableMark("ty_ex__qianxi-turn")
    mark[tostring(to.id)] = mark[tostring(to.id)] or {}
    table.insertIfNeed(mark[tostring(to.id)], color)
    room:setPlayerMark(player, "ty_ex__qianxi-turn", mark)
  end,
})

qianxi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if card and table.contains(player:getTableMark("@@ty_ex__qianxi-turn"), card:getColorString()) and
      card.color ~= Card.NoColor then
      local cards = card:isVirtual() and card.subcards or {card.id}
      return table.find(cards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if card and table.contains(player:getTableMark("@@ty_ex__qianxi-turn"), card:getColorString()) and
      card.color ~= Card.NoColor then
      local cards = card:isVirtual() and card.subcards or {card.id}
      return table.find(cards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})

qianxi:addEffect(fk.HpRecover, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:getMark("ty_ex__qianxi-turn") ~= 0 and
      player:getTableMark("ty_ex__qianxi-turn")[tostring(target.id)] ~= nil
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, qianxi.name)
  end,
})

qianxi:addEffect("invalidity", {
  invalidity_func = function(self, player, skill)
    if player:getMark("@@ty_ex__qianxi-turn") ~= 0 and
      skill:getSkeleton() and skill:getSkeleton().attached_equip and
      Fk:cloneCard(skill:getSkeleton().attached_equip).sub_type == Card.SubtypeArmor then

      if not RoomInstance then return end
      local logic = RoomInstance.logic
      local event = logic:getCurrentEvent()
      local from = nil
      repeat
        local data = event.data
        if event.event == GameEvent.SkillEffect then
          ---@cast data SkillEffectData
          if not data.skill.cardSkill then
            from = data.who
            break
          end
        elseif event.event == GameEvent.Damage then
          ---@cast data DamageData
          if data.to ~= player then return false end
          from = data.from
          break
        elseif event.event == GameEvent.UseCard then
          ---@cast data UseCardData
          if not table.contains(data.tos, player) then return false end
          from = data.from
          break
        end
        event = event.parent
      until event == nil
      if from and from:getMark("ty_ex__qianxi-turn") ~= 0 then
        for _, id in ipairs(player:getEquipments(Card.SubtypeArmor)) do
          local card = Fk:getCardById(id)
          if table.contains(from:getTableMark("ty_ex__qianxi-turn")[tostring(player.id)], card:getColorString()) and
            card.color ~= Card.NoColor and
            skill:getSkeleton().attached_equip == card.name then
            return true
          end
        end
      end
    end
  end,
})

return qianxi
