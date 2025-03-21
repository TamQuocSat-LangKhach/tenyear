local ty_ex__zhenwei = fk.CreateSkill {
  name = "ty_ex__zhenwei"
}

Fk:loadTranslationTable{
  ['ty_ex__zhenwei'] = '镇卫',
  ['#ty_ex__zhenwei-invoke'] = '镇卫：%src对%dest使用%arg，是否弃置一张牌发动“镇卫”？',
  ['ty_ex__zhenwei_transfer'] = '摸一张牌并将此牌转移给你',
  ['ty_ex__zhenwei_recycle'] = '取消此牌，回合结束时使用者将之收回',
  [':ty_ex__zhenwei'] = '当其他角色成为【杀】或黑色锦囊牌的唯一目标时，若该角色的体力值不大于你，你可以弃置一张牌并选择一项：1.摸一张牌，然后将此牌转移给你；2.令此牌无效，然后当前回合结束后，使用者获得此牌。',
  ['$ty_ex__zhenwei1'] = '想攻城，问过我没有？',
  ['$ty_ex__zhenwei2'] = '有我坐镇，我军焉能有失？',
}

ty_ex__zhenwei:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ty_ex__zhenwei.name) and not player:isNude() and data.from ~= player.id and data.to ~= player.id and
      (data.card.trueName == "slash" or (data.card.type == Card.TypeTrick and data.card.color == Card.Black)) and
      U.isOnlyTarget(target, data, event) and player.room:getPlayerById(data.to).hp <= player.hp
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ty_ex__zhenwei.name,
      cancelable = true,
      pattern = ".",
      prompt = "#ty_ex__zhenwei-invoke:" .. data.from .. ":" .. data.to .. ":" .. data.card:toLogString(),
      skip = true
    })
    if #cards > 0 then
      event:setCostData(self, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self), ty_ex__zhenwei.name, player, player)
    if player.dead then return false end
    local choice = room:askToChoice(player, {
      choices = {"ty_ex__zhenwei_transfer", "ty_ex__zhenwei_recycle"},
      skill_name = ty_ex__zhenwei.name
    })
    if choice == "ty_ex__zhenwei_transfer" then
      room:drawCards(player, 1, ty_ex__zhenwei.name)
      if player.dead then return false end
      if U.canTransferTarget(player, data) then
        local targets = {player.id}
        if type(data.subTargets) == "table" then
          table.insertTable(targets, data.subTargets)
        end
        AimGroup:addTargets(room, data, targets)
        AimGroup:cancelTarget(data, target.id)
        return true
      end
    else
      data.tos = AimGroup:initAimGroup({})
      data.targetGroup = {}
      local use_from = room:getPlayerById(data.from)
      if not use_from.dead and U.hasFullRealCard(room, data.card) then
        use_from:addToPile(ty_ex__zhenwei.name, data.card, true, ty_ex__zhenwei.name)
      end
      return true
    end
  end,
})

ty_ex__zhenwei:addEffect(fk.TurnEnd, {
  name = "#ty_ex__zhenwei_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getPile(ty_ex__zhenwei.name) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCards({
      from = player.id,
      ids = player:getPile(ty_ex__zhenwei.name),
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      skillName = ty_ex__zhenwei.name,
      proposer = player.id,
    })
  end,
})

return ty_ex__zhenwei
