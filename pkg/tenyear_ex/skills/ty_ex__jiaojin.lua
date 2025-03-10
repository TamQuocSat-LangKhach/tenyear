local ty_ex__jiaojin = fk.CreateSkill {
  name = "ty_ex__jiaoj__discard"
}

Fk:loadTranslationTable{
  ['ty_ex__jiaoj__discard'] = '骄矜',
  ['#ty_ex__jiaoj__discard'] = '骄矜：可弃置一张装备牌，令 %dest 使用的%arg对你无效，且结算后你获得之',
  [':ty_ex__jiaoj__discard'] = '当你成为其他角色使用【杀】或普通锦囊牌的目标后，你可以弃置一张装备牌，令此牌对你无效，然后此牌结算结束后你获得此牌。若该角色为女性，你的〖骄矜〗本回合无效。',
  ['$ty_ex__jiaojin1'] = '凭汝之力，何不自鉴？',
  ['$ty_ex__jiaojin2'] = '万金之躯，岂容狎侮！',
}

ty_ex__jiaojin:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__jiaojin) and data.from ~= player.id and (data.card.trueName == "slash" or data.card:isCommonTrick()) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ty_ex__jiaojin.name,
      cancelable = true,
      pattern = ".|.|.|.|.|equip",
      prompt = "#ty_ex__jiaoj__discard::" .. data.from .. ":" .. data.card:toLogString(),
      skip = true
    })
    if #cards > 0 then
      event:setCostData(self, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self), ty_ex__jiaojin.name, player)
    table.insertIfNeed(data.nullifiedTargets, player.id)
    data.extra_data = data.extra_data or {}
    local list = data.extra_data.ty_ex__jiaojin or {}
    table.insertIfNeed(list, player.id)
    data.extra_data.ty_ex__jiaojin = list
    if room:getPlayerById(data.from):isFemale() then
      room:invalidateSkill(player, ty_ex__jiaojin.name, "-turn")
    end
  end,
})

ty_ex__jiaojin:addEffect(fk.CardUseFinished, {
  name = "#ty_ex__jiaojin_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.ty_ex__jiaojin and table.contains(data.extra_data.ty_ex__jiaojin, player.id) and #player.room:getSubcardsByRule(data.card, {Card.Processing}) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getSubcardsByRule(data.card, {Card.Processing})
    room:obtainCard(player, ids, true, fk.ReasonJustMove)
  end,
})

return ty_ex__jiaojin
