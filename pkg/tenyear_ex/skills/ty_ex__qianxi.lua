local ty_ex__qianxi = fk.CreateSkill {
  name = "ty_ex__qianxi"
}

Fk:loadTranslationTable{
  ['ty_ex__qianxi'] = '潜袭',
  ['#ty_ex__qianxi-choose'] = '潜袭：令距离为1的一名角色：本回合不能使用或打出 %arg 的手牌，你无视其此颜色的防具',
  ['@ty_ex__qianxi-turn'] = '潜袭',
  ['#ty_ex__qianxi_delay'] = '潜袭',
  [':ty_ex__qianxi'] = '准备阶段，你可以摸一张牌，并弃置一张牌，然后选择一名距离为1的其他角色。若如此做，本回合：1.其不能使用或打出与你以此法弃置牌颜色相同的手牌；2.你无视其装备区里与你以此法弃置牌颜色相同的防具；3.你于该角色回复体力时摸两张牌。',
  ['$ty_ex__qianxi1'] = '暗影深处，袭敌斩首！',
  ['$ty_ex__qianxi2'] = '哼，出不了牌了吧？',
}

-- Trigger Skill Effect
ty_ex__qianxi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__qianxi) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:drawCards(player, 1, ty_ex__qianxi.name)
    if player.dead then return false end

    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ty_ex__qianxi.name,
      cancelable = false,
      pattern = ".",
      prompt = "#qianxi-discard",
      skip = true
    })

    if #cards == 0 then return false end
    local color = Fk:getCardById(cards[1]):getColorString()
    room:throwCard(cards, ty_ex__qianxi.name, player, player)

    local targets = table.map(table.filter(room.alive_players, function(p) 
      return player:distanceTo(p) == 1 
    end), Util.IdMapper)

    if #targets == 0 then return false end

    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__qianxi-choose:::" .. color,
      skill_name = ty_ex__qianxi.name,
      cancelable = false
    })

    if #to > 0 then
      room:setPlayerMark(room:getPlayerById(to[1]), "@ty_ex__qianxi-turn", color)
      room:addTableMark(player, "ty_ex__qianxi_targets-turn", to[1])
    end
  end,
})

-- Prohibit Skill Effect
ty_ex__qianxi:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    if player:getMark("@ty_ex__qianxi-turn") ~= 0 and card:getColorString() == player:getMark("@ty_ex__qianxi-turn") then
      local cards = card:isVirtual() and card.subcards or {card.id}
      return table.find(cards, function(id) return table.contains(player.player_cards[Player.Hand], id) end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@ty_ex__qianxi-turn") ~= 0 and card:getColorString() == player:getMark("@ty_ex__qianxi-turn") then
      local cards = card:isVirtual() and card.subcards or {card.id}
      return table.find(cards, function(id) return table.contains(player.player_cards[Player.Hand], id) end)
    end
  end,
})

-- Delay Trigger Skill Effect
ty_ex__qianxi:addEffect(fk.HpRecover, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and table.contains(player:getTableMark("ty_ex__qianxi_targets-turn"), target.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, ty_ex__qianxi.name)
  end,
})

-- Invalidity Skill Effect
ty_ex__qianxi:addEffect('invalidity', {
  invalidity_func = function(self, player, skill)
    local color = player:getMark("@ty_ex__qianxi-turn")
    if color == 0 then return false end

    local armors = player:getEquipments(Card.SubtypeArmor)
    local falsy = true
    for _, id in ipairs(armors) do
      local card = Fk:getCardById(id)
      if table.contains(card:getEquipSkills(player), skill) then
        if card:getColorString() ~= color then return false end
        falsy = false
      end
    end

    if falsy then return false end

    -- 无视防具（规则集版）！
    if RoomInstance then
      local logic = RoomInstance.logic
      local event = logic:getCurrentEvent()
      local from = nil
      repeat
        if event.event == GameEvent.SkillEffect then
          if not event.data[3].cardSkill then
            from = event.data[2]
            break
          end
        elseif event.event == GameEvent.Damage then
          local damage = event.data[1]
          if damage.to.id ~= player.id then return false end
          from = damage.from
          break
        elseif event.event == GameEvent.UseCard then
          local use = event.data[1]
          if not table.contains(TargetGroup:getRealTargets(use.tos), player.id) then return false end
          from = RoomInstance:getPlayerById(use.from)
          break
        end
        event = event.parent
      until event == nil

      if from then
        return table.contains(from:getTableMark("ty_ex__qianxi_targets-turn"), player.id)
      end
    end
  end,
})

return ty_ex__qianxi
