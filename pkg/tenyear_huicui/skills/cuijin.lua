local cuijin = fk.CreateSkill {
  name = "ty__cuijin",
}

Fk:loadTranslationTable{
  ["ty__cuijin"] = "催进",
  [":ty__cuijin"] = "当你或攻击范围内的角色使用【杀】或【决斗】时，你可以弃置一张牌，令此【杀】或【决斗】的伤害值基数+1。"..
  "当此牌结算结束后，若此牌未造成伤害，你摸两张牌，对使用者造成1点伤害。",

  ["#ty__cuijin-ask"] = "催进：是否弃置一张牌，令 %dest 使用的%arg伤害+1？若未造成伤害，你摸两张牌并对 %dest 造成1点伤害。",

  ["$ty__cuijin1"] = "军令如山，诸君焉敢不前？",
  ["$ty__cuijin2"] = "前攻者赏之，后靡斩之！"
}

cuijin:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(cuijin.name) and table.contains({"slash", "duel"}, data.card.trueName) and
      (player:inMyAttackRange(target) or target == player) and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = cuijin.name,
      cancelable = true,
      prompt = "#ty__cuijin-ask::"..target.id..":"..data.card:toLogString(),
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, cuijin.name, player, player)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__cuijin = data.extra_data.ty__cuijin or {}
    table.insert(data.extra_data.ty__cuijin, player.id)
  end,
})

cuijin:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not data.damageDealt and data.extra_data and data.extra_data.ty__cuijin and
      table.contains(data.extra_data.ty__cuijin, player.id) and
      not player.dead
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, cuijin.name)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = cuijin.name,
      }
    end
  end,
})

return cuijin
