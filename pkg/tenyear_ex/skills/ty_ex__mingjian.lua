local ty_ex__mingjian = fk.CreateSkill {
  name = "ty_ex__mingjian"
}

Fk:loadTranslationTable{
  ['ty_ex__mingjian'] = '明鉴',
  ['#ty_ex__mingjian-active'] = '发动 明鉴，将所有手牌交给一名角色，令其下个回合获得增益',
  ['@@ty_ex__mingjian'] = '明鉴',
  [':ty_ex__mingjian'] = '出牌阶段限一次，你可以将所有手牌交给一名其他角色，然后该角色下回合：使用【杀】的次数上限和手牌上限+1；首次造成伤害后，你可以发动〖恢拓〗。',
  ['$ty_ex__mingjian1'] = '敌将寇边，还请将军领兵御之。',
  ['$ty_ex__mingjian2'] = '逆贼滔乱，须得阁下出手相助。',
}

ty_ex__mingjian:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#ty_ex__mingjian-active",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(ty_ex__mingjian.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(player:getCardIds(Player.Hand), Player.Hand, target, fk.ReasonGive, ty_ex__mingjian.name, nil, false, player.id)
    room:addPlayerMark(target, "@@" .. ty_ex__mingjian.name, 1)
  end,
})

ty_ex__mingjian:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@@ty_ex__mingjian") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("@@ty_ex__mingjian")
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, x)
    room:addPlayerMark(player, MarkEnum.SlashResidue .. "-turn", x)

    local turn_event = room.logic:getCurrentEvent()
    turn_event:addCleaner(function()
      room:removePlayerMark(player, "@@ty_ex__mingjian", x)
    end)
  end,
})

return ty_ex__mingjian
