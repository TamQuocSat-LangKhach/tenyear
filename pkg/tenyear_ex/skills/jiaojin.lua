local jiaojin = fk.CreateSkill {
  name = "ty_ex__jiaojin",
}

Fk:loadTranslationTable{
  ["ty_ex__jiaojin"] = "骄矜",
  [":ty_ex__jiaojin"] = "当你成为其他角色使用【杀】或普通锦囊牌的目标后，你可以弃置一张装备牌，令此牌对你无效，此牌结算结束后你获得之。"..
  "若该角色为女性，〖骄矜〗本回合失效。",

  ["#ty_ex__jiaojin-invoke"] = "骄矜：弃置一张装备牌，令 %dest 使用的%arg对你无效，结算后你获得之",

  ["$ty_ex__jiaojin1"] = "凭汝之力，何不自鉴？",
  ["$ty_ex__jiaojin2"] = "万金之躯，岂容狎侮！",
}

jiaojin:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiaojin.name) and
    (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      data.from ~= player and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jiaojin.name,
      cancelable = true,
      pattern = ".|.|.|.|.|equip",
      prompt = "#ty_ex__jiaoj__discard::" .. data.from.id .. ":" .. data.card:toLogString(),
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, jiaojin.name, player)
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)
    data.extra_data = data.extra_data or {}
    local list = data.extra_data.ty_ex__jiaojin or {}
    table.insertIfNeed(list, player.id)
    data.extra_data.ty_ex__jiaojin = list
    if data.from:isFemale() then
      room:invalidateSkill(player, jiaojin.name, "-turn")
    end
  end,
})

jiaojin:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.ty_ex__jiaojin and
      table.contains(data.extra_data.ty_ex__jiaojin, player.id) and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, jiaojin.name)
  end,
})

return jiaojin
