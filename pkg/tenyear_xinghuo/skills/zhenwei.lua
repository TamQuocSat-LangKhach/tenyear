local zhenwei = fk.CreateSkill {
  name = "ty_ex__zhenwei",
}

Fk:loadTranslationTable{
  ["ty_ex__zhenwei"] = "镇卫",
  [":ty_ex__zhenwei"] = "当其他角色成为【杀】或黑色锦囊牌的唯一目标时，若该角色的体力值不大于你，你可以弃置一张牌并选择一项：1.摸一张牌，"..
  "然后将此牌转移给你；2.令此牌无效，然后当前回合结束后，使用者获得此牌。",

  ["#ty_ex__zhenwei-invoke"] = "镇卫：%src 对 %dest 使用%arg，你可以弃置一张牌执行一项",

  ["$ty_ex__zhenwei1"] = "想攻城，问过我没有？",
  ["$ty_ex__zhenwei2"] = "有我坐镇，我军焉能有失？",
}

zhenwei:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhenwei.name) and not player:isNude() and data.from ~= player and target ~= player and
      (data.card.trueName == "slash" or (data.card.type == Card.TypeTrick and data.card.color == Card.Black)) and
      data:isOnlyTarget(target) and target.hp <= player.hp
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "zhenwei_active",
      prompt = "#ty_ex__zhenwei-invoke:"..data.from.id..":"..data.to.id..":"..data.card:toLogString(),
      cancelable = true,
      extra_data = {
        from = data.from.id,
        card = data.card:toLogString(),
      }
    })
    if success and dat then
      event:setCostData(self, {tos = {target}, choice = dat.interaction, cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:throwCard(event:getCostData(self).cards, zhenwei.name, player, player)
    if choice:startsWith("zhenwei_transfer") then
      data:cancelTarget(target)
      if not player.dead then
        player:drawCards(1, zhenwei.name)
      end
      if not data.from:isProhibited(player, data.card) and not player.dead then
        data:addTarget(player)
      end
    else
      data.use.nullifiedTargets = table.simpleClone(room.players)
      if not data.from.dead and room:getCardArea(data.card) == Card.Processing then
        data.from:addToPile(zhenwei.name, data.card, true, zhenwei.name)
      end
    end
  end,
})

zhenwei:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getPile(zhenwei.name) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile(zhenwei.name), Card.PlayerHand, player, fk.ReasonJustMove)
  end,
})

return zhenwei
