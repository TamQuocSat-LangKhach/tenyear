local ruyi = fk.CreateSkill {
  name = "ruyi"
}

Fk:loadTranslationTable{
  ['ruyi'] = '如意',
  ['#ruyi'] = '如意：选择你的攻击范围',
  ['@ruyi'] = '如意',
  ['#ruyi_filter'] = '如意',
  ['#ruyi_trigger'] = '如意',
  ['#ruyi-choose'] = '如意：%arg 可额外选择一个目标',
  [':ruyi'] = '锁定技，你手牌中的武器牌均视为【杀】，你废除武器栏。你的攻击范围基数为3，出牌阶段限一次，你可以调整攻击范围（1~4）。若你的攻击范围基数为：1，使用【杀】无次数限制；2，使用【杀】伤害+1；3，使用【杀】无法响应；4，使用【杀】可额外选择一个目标。',
  ['$ruyi1'] = '俺老孙来也！',
  ['$ruyi2'] = '吃俺老孙一棒！'
}

-- Active Skill
ruyi:addEffect('active', {
  name = "ruyi",
  prompt = "#ruyi",
  frequency = Skill.Compulsory,
  card_num = 0,
  target_num = 0,
  interaction = function()
    return UI.Spin { from = 1, to = 4 }
  end,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(ruyi.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "@ruyi", skill.interaction.data)
  end,
})

-- Attack Range Skill
ruyi:addEffect('atkrange', {
  name = "#ruyi_attackrange",
  fixed_func = function (skill, player)
    if player:hasSkill(ruyi) and player:getMark("@ruyi") ~= 0 then
      return player:getMark("@ruyi")
    end
  end,
})

-- Filter Skill
ruyi:addEffect('filter', {
  name = "#ruyi_filter",
  card_filter = function(self, card, player)
    return player:hasSkill(ruyi) and card.sub_type == Card.SubtypeWeapon and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = "ruyi"
    return c
  end,
})

-- TargetMod Skill
ruyi:addEffect('targetmod', {
  name = "#ruyi_targetmod",
  bypass_times = function(self, player, skillObj, scope)
    return player:hasSkill(ruyi) and player:getMark("@ruyi") <= 1 and skillObj.trueName == "slash_skill" and scope == Player.HistoryPhase
  end,
})

-- Trigger Skill
ruyi:addEffect(fk.AfterCardUseDeclared, {
  name = "#ruyi_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(ruyi) then
      return player:getMark("@ruyi") == 2 or player:getMark("@ruyi") == 3
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@ruyi") == 2 then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    elseif player:getMark("@ruyi") == 3 then
      data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
    end
  end,
})

ruyi:addEffect(fk.AfterCardTargetDeclared, {
  name = "#ruyi_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(ruyi) then
      return player:getMark("@ruyi") == 4 and #player.room:getUseExtraTargets(data) > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@ruyi") == 4 then
      local to = room:askToChoosePlayers(player, {
        targets = room:getUseExtraTargets(data),
        min_num = 1,
        max_num = 1,
        prompt = "#ruyi-choose:::"..data.card:toLogString(),
        skill_name = ruyi.name,
        cancelable = true
      })
      if #to > 0 then
        table.insert(data.tos, to)
      end
    end
  end,
})

ruyi:addEffect(fk.EventAcquireSkill, {
  name = "#ruyi_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return data == ruyi and target == player and player.room:getBanner("RoundCount")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@ruyi", 3)
    if table.contains(player:getAvailableEquipSlots(), Player.WeaponSlot) then
      room:abortPlayerArea(player, Player.WeaponSlot)
    end
  end,
})

ruyi:addEffect(fk.GameStart, {
  name = "#ruyi_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasShownSkill(ruyi, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@ruyi", 3)
    if table.contains(player:getAvailableEquipSlots(), Player.WeaponSlot) then
      room:abortPlayerArea(player, Player.WeaponSlot)
    end
  end,
})

return ruyi
