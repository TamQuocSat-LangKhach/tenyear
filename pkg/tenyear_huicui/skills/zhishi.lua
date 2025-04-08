local zhishi = fk.CreateSkill {
  name = "zhishi",
}

Fk:loadTranslationTable{
  ["zhishi"] = "指誓",
  [":zhishi"] = "结束阶段，你可以选择一名角色，直到你下回合开始，该角色成为【杀】的目标后或进入濒死状态时，你可以移去任意张“疠”，"..
  "令其摸等量的牌。",

  ["#zhishi-choose"] = "指誓：选择一名角色，当其成为【杀】的目标或进入濒死状态时，你可以移去“疠”令其摸牌",
  ["#zhishi-invoke"] = "指誓：你可以移去任意张“疠”，令 %dest 摸等量的牌",

  ["$zhishi1"] = "嚼指为誓，誓杀国贼！",
  ["$zhishi2"] = "心怀汉恩，断指相随。",
}

zhishi:addEffect(fk.EventPhaseStart , {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhishi.name) and player.phase == Player.Finish
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#zhishi-choose",
      skill_name = zhishi.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(player, zhishi.name, to.id)
  end,
})

local spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      pattern = ".|.|.|jiping_li",
      prompt = "#zhishi-invoke::"..target.id,
      skill_name = zhishi.name,
      expand_pile = "jiping_li",
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {target}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, zhishi.name, nil, true, player)
    if not target.dead then
      target:drawCards(#cards, zhishi.name)
    end
  end,
}

zhishi:addEffect(fk.TargetConfirmed , {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(zhishi.name) and player:getMark(zhishi.name) == target.id and not target.dead and
      data.card.trueName == "slash" and #player:getPile("jiping_li") > 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})
zhishi:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(zhishi.name) and player:getMark(zhishi.name) == target.id and not target.dead and
      #player:getPile("jiping_li") > 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

zhishi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(zhishi.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, zhishi.name, 0)
  end,
})

zhishi:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark(zhishi.name) == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, zhishi.name, 0)
  end,
})

return zhishi
