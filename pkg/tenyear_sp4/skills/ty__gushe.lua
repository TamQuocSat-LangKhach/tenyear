local ty__gushe = fk.CreateSkill {
  name = "ty__gushe"
}

Fk:loadTranslationTable{
  ['ty__gushe'] = '鼓舌',
  ['#ty__gushe-active'] = '发动 鼓舌，与1-3名角色拼点！',
  ['@ty__raoshe'] = '饶舌',
  ['#ty__gushe_delay'] = '鼓舌',
  ['#ty__gushe-discard'] = '鼓舌：你需弃置一张牌，否则 %src 摸一张牌',
  ['#ty__gushe2-discard'] = '鼓舌：你需弃置一张牌',
  [':ty__gushe'] = '出牌阶段，你可以用一张手牌与至多三名角色同时拼点，没赢的角色选择一项: 1.弃置一张牌；2.令你摸一张牌。若你没赢，获得一个“饶舌”标记；若你有7个“饶舌”标记，你死亡。当你一回合内累计七次拼点赢时（每有一个“饶舌”标记，此累计次数减1），本回合此技能失效。',
  ['$ty__gushe1'] = '承寇贼之要，相时而后动，择地而后行，一举更无余事。',
  ['$ty__gushe2'] = '春秋之义，求诸侯莫如勤王。今天王在魏都，宜遣使奉承王命。',
}

ty__gushe:addEffect('active', {
  name = "ty__gushe",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  prompt = "#ty__gushe-active",
  times = function(self)
    return self.player.phase ~= Player.NotActive and 7 - self.player:getMark("ty__raoshe_win-turn") - self.player:getMark("@ty__raoshe") or -1
  end,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 3 and self.player:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local tos = table.simpleClone(effect.tos)
    room:sortPlayersByAction(tos)
    room:getPlayerById(effect.from):pindian(table.map(tos, function(p) return room:getPlayerById(p) end), ty__gushe.name)
  end,
})

ty__gushe:addEffect(fk.PindianResultConfirmed, {
  name = "#ty__gushe_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return data.reason == "ty__gushe" and data.from == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.dead and data.winner ~= player then
      room:addPlayerMark(player, "@ty__raoshe", 1)
      if player:getMark("@ty__raoshe") >= 7 then
        room:killPlayer({who = player.id,})
      end
      if not player.dead then
        local discards = room:askToDiscard(player, {min_num = 1, max_num = 1, include_equip = true, skill_name = ty__gushe.name, cancelable = true, pattern = ".", prompt = "#ty__gushe-discard:" .. player.id})
        if #discards == 0 then
          player:drawCards(1, ty__gushe.name)
        end
      end
    end
    if not data.to.dead and data.winner ~= data.to then
      if player.dead then
        room:askToDiscard(data.to, {min_num = 1, max_num = 1, include_equip = true, skill_name = ty__gushe.name, cancelable = false, pattern = ".", prompt = "#ty__gushe2-discard"})
      else
        local discards = room:askToDiscard(data.to, {min_num = 1, max_num = 1, include_equip = true, skill_name = ty__gushe.name, cancelable = true, pattern = ".", prompt = "#ty__gushe-discard:" .. player.id})
        if #discards == 0 then
          player:drawCards(1, ty__gushe.name)
        end
      end
    end
  end,

  can_refresh = function(self, event, target, player, data)
    if event == fk.PindianResultConfirmed then
      return data.winner and data.winner == player and player:hasSkill(ty__gushe, true)
    elseif event == fk.EventLoseSkill then
      return player == target and data == ty__gushe
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PindianResultConfirmed then
      room:addPlayerMark(player, "ty__raoshe_win-turn")
      if player:getMark("@ty__raoshe") + player:getMark("ty__raoshe_win-turn") > 6 then
        room:invalidateSkill(player, ty__gushe.name, "-turn")
      end
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@ty__raoshe", 0)
      room:setPlayerMark(player, "ty__raoshe_win-turn", 0)
    end
  end,
})

return ty__gushe
