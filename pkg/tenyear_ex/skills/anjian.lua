local anjian = fk.CreateSkill {
  name = "ty_ex__anjian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_ex__anjian"] = "暗箭",
  [":ty_ex__anjian"] = "锁定技，当你使用【杀】指定目标后，若你不在其攻击范围内，此【杀】无视其防具且伤害+1；"..
  "若该角色因此进入濒死状态，其不能使用【桃】直到此次濒死结算结束。",

  ["$ty_ex__anjian1"] = "暗箭中人，其疮及骨！",
  ["$ty_ex__anjian2"] = "战阵之间，不厌诈伪！",
}

anjian:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(anjian.name) and data.card.trueName == "slash" and
      not data.to:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.to:addQinggangTag(data)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty_ex__anjian = data.extra_data.ty_ex__anjian or {}
    data.extra_data.ty_ex__anjian[data.to] = (data.extra_data.ty_ex__anjian[data.to] or 0) + 1
  end,
})

local spec = {
  can_refresh = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data
        if use.extra_data and use.extra_data.ty_ex__anjian and use.extra_data.ty_ex__anjian[target] then
          return true
        end
      end
    end
  end,
}
anjian:addEffect(fk.EnterDying, {
  can_refresh = spec.can_refresh,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, anjian.name)
  end,
})
anjian:addEffect(fk.AfterDying, {
  can_refresh = spec.can_refresh,
  on_refresh = function(self, event, target, player, data)
    player.room:removePlayerMark(player, anjian.name)
  end,
})

anjian:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and card.name == "peach" and player:getMark(anjian.name) > 0
  end,
})

return anjian
