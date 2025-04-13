local mingjian = fk.CreateSkill {
  name = "ty_ex__mingjian",
}

Fk:loadTranslationTable{
  ["ty_ex__mingjian"] = "明鉴",
  [":ty_ex__mingjian"] = "出牌阶段限一次，你可以将所有手牌交给一名其他角色，该角色下回合：使用【杀】次数上限和手牌上限+1；"..
  "首次造成伤害后，你可以发动〖恢拓〗。",

  ["#ty_ex__mingjian"] = "明鉴：将所有手牌交给一名角色，其下回合手牌上限和【杀】次数+1",
  ["@@ty_ex__mingjian"] = "明鉴",
  ["@@ty_ex__mingjian-turn"] = "明鉴",

  ["$ty_ex__mingjian1"] = "敌将寇边，还请将军领兵御之。",
  ["$ty_ex__mingjian2"] = "逆贼滔乱，须得阁下出手相助。",
}

mingjian:addEffect("active", {
  anim_type = "support",
  prompt = "#ty_ex__mingjian",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(mingjian.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(target, "@@ty_ex__mingjian", player.id)
    room:moveCardTo(player:getCardIds("h"), Player.Hand, target, fk.ReasonGive, mingjian.name, nil, false, player)
  end,
})

mingjian:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@ty_ex__mingjian") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ty_ex__mingjian-turn", player:getMark("@@ty_ex__mingjian"))
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, #player:getTableMark("@@ty_ex__mingjian"))
    room:setPlayerMark(player, "@@ty_ex__mingjian", 0)
  end,
})

mingjian:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if player:getMark("@@ty_ex__mingjian-turn") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return #player:getTableMark("@@ty_ex__mingjian-turn")
    end
  end,
})

mingjian:addEffect(fk.Damage, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target and table.contains(target:getTableMark("@@ty_ex__mingjian-turn"), player.id) and not player.dead then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return end
      local damage_events = player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == target
      end, nil, turn_event.id)
      return #damage_events == 1 and damage_events[1].data == data
    end
  end,
  on_cost = function (self, event, target, player, data)
    Fk.skills["huituo"]:doCost(event, target, player, data)
  end,
})

return mingjian
