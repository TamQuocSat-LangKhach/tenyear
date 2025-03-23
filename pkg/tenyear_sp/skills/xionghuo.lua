local xionghuo = fk.CreateSkill {
  name = "xionghuo",
}

Fk:loadTranslationTable{
  ["xionghuo"] = "凶镬",
  [":xionghuo"] = "游戏开始时，你获得3个“暴戾”标记（标记上限为3）。出牌阶段，你可以交给一名其他角色一个“暴戾”标记，"..
  "你对有此标记的其他角色造成的伤害+1，且其出牌阶段开始时，移去“暴戾”并随机执行一项：1.受到1点火焰伤害且本回合不能对你使用【杀】；"..
  "2.流失1点体力且本回合手牌上限-1；3.你随机获得其两张牌。",

  ["#xionghuo"] = "凶镬：将“暴戾”交给其他角色",
  ["@baoli"] = "暴戾",

  ["$xionghuo1"] = "此镬加之于你，定有所伤！",
  ["$xionghuo2"] = "凶镬沿袭，怎会轻易无伤？",
}

xionghuo:addEffect("active", {
  anim_type = "offensive",
  prompt = "#xionghuo",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("@baoli") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:getMark("@baoli") == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:removePlayerMark(player, "@baoli", 1)
    room:addPlayerMark(target, "@baoli", 1)
  end,
})

xionghuo:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xionghuo.name) and player:getMark("@baoli") < 3
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@baoli", 3 - player:getMark("@baoli"))
  end,
})

xionghuo:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xionghuo.name) and data.to ~= player and data.to:getMark("@baoli") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1)
  end,
})

xionghuo:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xionghuo.name) and target.phase == Player.Play and
      target:getMark("@baoli") > 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(target, "@baoli", 1)
    local rand = math.random(1, target:isNude() and 2 or 3)
    if rand == 1 then
      room:addTableMark(target, "xionghuo_prohibit-turn", player.id)
      room:damage {
        from = player,
        to = target,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = xionghuo.name,
      }
    elseif rand == 2 then
      room:addPlayerMark(target, "MinusMaxCards-turn", 1)
      room:loseHp(target, 1, xionghuo.name)
    elseif rand == 3 then
      room:moveCardTo(table.random(target:getCardIds("he"), 2), Player.Hand, player, fk.ReasonPrey, xionghuo.name, nil, false, player)
    end
  end,
})

xionghuo:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and card.trueName == "slash" and table.contains(from:getTableMark("xionghuo_prohibit-turn"), to.id)
  end,
})

return xionghuo
