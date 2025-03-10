local ty_ex__anjian = fk.CreateSkill {
  name = "ty_ex__anjian"
}

Fk:loadTranslationTable{
  ['ty_ex__anjian'] = '暗箭',
  [':ty_ex__anjian'] = '锁定技，当你使用【杀】指定一名角色为目标后，若你不在其攻击范围内，此【杀】对其造成的基础伤害值+1且无视其防具，然后若该角色因此进入濒死状态，其不能使用【桃】直到此次濒死结算结束。',
  ['$ty_ex__anjian1'] = '暗箭中人，其疮及骨！',
  ['$ty_ex__anjian2'] = '战阵之间，不厌诈伪！',
}

ty_ex__anjian:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__anjian.name) and data.card.trueName == "slash"
      and not player.room:getPlayerById(data.to):inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.additionalDamage = (data.additionalDamage or 0) + 1
    room:getPlayerById(data.to):addQinggangTag(data)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty_ex__anjian = data.extra_data.ty_ex__anjian or {}
    data.extra_data.ty_ex__anjian[tostring(data.to)] = (data.extra_data.ty_ex__anjian[tostring(data.to)] or 0) + 1
  end,
})

ty_ex__anjian:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    if player == target then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data[1]
        if use.extra_data and use.extra_data.ty_ex__anjian and use.extra_data.ty_ex__anjian[tostring(math.floor(target.id))] then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EnterDying then
      player.room:addPlayerMark(player, "ty_ex__anjian_poison")
    else
      player.room:removePlayerMark(player, "ty_ex__anjian_poison")
    end
  end,
})

ty_ex__anjian:addEffect('prohibit', {
  name = "#ty_ex__anjian_prohibit",
  prohibit_use = function(self, player, card)
    return card and card.name == "peach" and player:getMark("ty_ex__anjian_poison") > 0
  end,
})

return ty_ex__anjian
