local jiudun = fk.CreateSkill {
  name = "jiudun"
}

Fk:loadTranslationTable{
  ['jiudun'] = '酒遁',
  ['@jiudun_drank'] = '酒',
  ['#jiudun-invoke'] = '酒遁：你可以摸一张牌，视为使用【酒】',
  ['#jiudun-card'] = '酒遁：你可以弃置一张手牌，令%arg对你无效',
  ['#jiudun_rule'] = '酒遁',
  [':jiudun'] = '以使用方法①使用的【酒】对你的作用效果改为：目标角色使用的下一张[杀]的伤害值基数+1。当你成为其他角色使用黑色牌的目标后，若你未处于【酒】状态，你可以摸一张牌并视为使用一张【酒】；若你处于【酒】状态，你可以弃置一张手牌令此牌对你无效。',
  ['$jiudun1'] = '籍不胜酒力，恐失言失仪。',
  ['$jiudun2'] = '秋月春风正好，不如大醉归去。',
}

jiudun:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiudun) and data.card.color == Card.Black and data.from ~= player.id and
      (player.drank + player:getMark("@jiudun_drank") == 0 or not player:isKongcheng())
  end,
  on_cost = function(self, event, target, player, data)
    if player.drank + player:getMark("@jiudun_drank") == 0 then
      return player.room:askToSkillInvoke(player, {
        skill_name = jiudun.name,
        prompt = "#jiudun-invoke"
      })
    else
      local card = player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        pattern = ".|.|.|hand",
        prompt = "#jiudun-card:::" .. data.card:toLogString(),
        cancelable = true
      })
      if #card > 0 then
        event:setCostData(self, card)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.drank + player:getMark("@jiudun_drank") == 0 then
      player:drawCards(1, jiudun.name)
      room:useVirtualCard("analeptic", nil, player, player, jiudun.name, false)
    else
      local a = event:getCostData(self)
      room:throwCard(a, jiudun.name, player, player)
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      else
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    end
  end,
})

jiudun:addEffect(fk.PreCardEffect, {
  name = "#jiudun_rule",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiudun) and data.to == player.id and data.card.trueName == "analeptic" and
      not (data.extra_data and data.extra_data.analepticRecover)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    card.skill = jiudun__analepticSkill
    data.card = card
  end,
})

jiudun:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return player == target and data.card.trueName == "slash" and player:getMark("@jiudun_drank") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@jiudun_drank")
    data.extra_data = data.extra_data or {}
    data.extra_data.drankBuff = player:getMark("@jiudun_drank")
    player.room:setPlayerMark(player, "@jiudun_drank", 0)
  end,
})

return jiudun
