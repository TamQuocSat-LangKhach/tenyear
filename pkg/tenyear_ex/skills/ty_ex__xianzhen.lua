local ty_ex__xianzhen = fk.CreateSkill {
  name = "ty_ex__xianzhen"
}

Fk:loadTranslationTable{
  ['ty_ex__xianzhen'] = '陷阵',
  ['@@ty_ex__xianzhen-turn'] = '陷阵',
  [':ty_ex__xianzhen'] = '每回合限一次，出牌阶段，你可以与一名角色拼点：若你赢，本回合你无视该角色的防具、对其使用牌无距离和次数限制，且你本回合使用牌对其造成伤害时，此伤害+1（每种牌名限一次）；若你没赢，本回合你不能使用【杀】且你的【杀】不计入手牌上限。',
  ['$ty_ex__xianzhen1'] = '精练整齐，每战必克！',
  ['$ty_ex__xianzhen2'] = '陷阵杀敌，好不爽快！',
}

-- Active Skill
ty_ex__xianzhen:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(ty_ex__xianzhen.name, Player.HistoryTurn) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id and player:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, ty_ex__xianzhen.name)
    if pindian.results[target.id].winner == player then
      room:setPlayerMark(target, "@@ty_ex__xianzhen-turn", 1)
      room:addTableMark(player, fk.MarkArmorInvalidTo .. "-turn", target.id)
    else
      room:setPlayerMark(player, "ty_ex__xianzhen_lose-turn", 1)
    end
  end,
})

-- Trigger Skill
ty_ex__xianzhen:addEffect(fk.DamageCaused, {
  name = "#ty_ex__xianzhen_trigger",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:usedSkillTimes(ty_ex__xianzhen.name, Player.HistoryTurn) > 0 and data.card
      and data.to:getMark("@@ty_ex__xianzhen-turn") > 0 then
      local mark = player:getTableMark("ty_ex__xianzhen_damage-turn")
      return not table.contains(mark, data.card.trueName)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, "ty_ex__xianzhen_damage-turn", data.card.trueName)
    data.damage = data.damage + 1
  end,
})

-- TargetMod Skill
ty_ex__xianzhen:addEffect('targetmod', {
  name = "#ty_ex__xianzhen_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:usedSkillTimes(ty_ex__xianzhen.name, Player.HistoryTurn) > 0 and to and to:getMark("@@ty_ex__xianzhen-turn") > 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:usedSkillTimes(ty_ex__xianzhen.name, Player.HistoryTurn) > 0 and to and to:getMark("@@ty_ex__xianzhen-turn") > 0
  end,
})

-- Prohibit Skill
ty_ex__xianzhen:addEffect('prohibit', {
  name = "#ty_ex__xianzhen_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("ty_ex__xianzhen_lose-turn") > 0 then
      return card.trueName == "slash"
    end
    if table.find(Fk:currentRoom().alive_players, function (p)
      return p ~= player and p:hasSkill(ty_ex__xianzhen) and p.phase ~= Player.NotActive
    end) then
      return card.trueName == "analeptic"
    end
  end,
})

-- MaxCards Skill
ty_ex__xianzhen:addEffect('maxcards', {
  name = "#ty_ex__xianzhen_maxcards",
  exclude_from = function(self, player, card)
    return card.trueName == "slash" and player:getMark("ty_ex__xianzhen_lose-turn") > 0
  end,
})

return ty_ex__xianzhen
