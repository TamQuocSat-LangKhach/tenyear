local ty__zhongjian = fk.CreateSkill {
  name = "ty__zhongjian"
}

Fk:loadTranslationTable{
  ['ty__zhongjian'] = '忠鉴',
  ['ty__zhongjian_draw'] = '受到伤害后摸牌',
  ['ty__zhongjian_discard'] = '造成伤害后弃牌',
  ['#ty__zhongjian_trigger'] = '忠鉴',
  [':ty__zhongjian'] = '出牌阶段限一次，你可以秘密选择一名本回合未选择过的角色，并秘密选一项，直到你的下回合开始：1.当该角色下次造成伤害后，其弃置两张牌；2.当该角色下次受到伤害后，其摸两张牌。当〖忠鉴〗被触发时，你摸一张牌。',
  ['$ty__zhongjian1'] = '闻大忠似奸、大智若愚，不辨之难鉴之。',
  ['$ty__zhongjian2'] = '以眼为镜可正衣冠，以心为镜可鉴忠奸。',
}

-- Active Skill Effect
ty__zhongjian:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  no_indicate = true,
  interaction = function(self)
    return UI.ComboBox { choices = {"ty__zhongjian_draw","ty__zhongjian_discard"} }
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark("ty__zhongjian_target-turn") == 0
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(ty__zhongjian.name, Player.HistoryPhase) < (1 + player:getMark("ty__caishi_twice-turn"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(to, "ty__zhongjian_target-turn", 1)
    local choice = self.interaction.data
    room:addTableMark(to, choice, player.id)
  end,
})

-- Trigger Skill Effect
ty__zhongjian:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    return target and not target.dead and #target:getTableMark("ty__zhongjian_discard") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = "ty__zhongjian_discard"
    local mark = player:getTableMark(choice)
    room:setPlayerMark(player, choice, 0)
    room:sortPlayersByAction(mark)
    for _, pid in ipairs(mark) do
      if player.dead then break end
      local p = room:getPlayerById(pid)
      room:askToDiscard(target, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = ty__zhongjian.name,
        cancelable = false,
      })
      if not p.dead then
        p:drawCards(1, ty__zhongjian.name)
      end
    end
  end,
})

-- Trigger Skill Effect for Damaged event
ty__zhongjian:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    return not target.dead and #target:getTableMark("ty__zhongjian_draw") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = "ty__zhongjian_draw"
    local mark = player:getTableMark(choice)
    room:setPlayerMark(player, choice, 0)
    room:sortPlayersByAction(mark)
    for _, pid in ipairs(mark) do
      if player.dead then break end
      local p = room:getPlayerById(pid)
      target:drawCards(2, ty__zhongjian.name)
      if not p.dead then
        p:drawCards(1, ty__zhongjian.name)
      end
    end
  end,
})

-- Refresh Effects for TurnStart event
ty__zhongjian:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return table.contains(player:getTableMark("ty__zhongjian_discard"), target.id) or 
      table.contains(player:getTableMark("ty__zhongjian_draw"), target.id)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, mark in ipairs({"ty__zhongjian_discard","ty__zhongjian_draw"}) do
      room:setPlayerMark(player, mark, table.filter(player:getTableMark(mark), function (pid)
        return pid ~= target.id
      end))
    end
  end,
})

return ty__zhongjian
