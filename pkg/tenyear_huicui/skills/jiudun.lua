local jiudun = fk.CreateSkill {
  name = "jiudun",
}

Fk:loadTranslationTable{
  ["jiudun"] = "酒遁",
  [":jiudun"] = "你的【酒】状态改为获得一枚不会因回合结束而消失的“酒”标记。当你成为其他角色使用黑色牌的目标后，若你未处于【酒】状态，"..
  "你可以摸一张牌并视为使用一张【酒】；若你处于【酒】状态，你可以弃置一张手牌令此牌对你无效。",

  ["@jiudun_drank"] = "酒",
  ["#jiudun-invoke"] = "酒遁：你可以摸一张牌，视为使用【酒】",
  ["#jiudun-card"] = "酒遁：你可以弃置一张手牌，令%arg对你无效",

  ["$jiudun1"] = "籍不胜酒力，恐失言失仪。",
  ["$jiudun2"] = "秋月春风正好，不如大醉归去。",
}

jiudun:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiudun.name) and
      data.card.color == Card.Black and data.from ~= player and
      (player.drank + player:getMark("@jiudun_drank") == 0 or not player:isKongcheng())
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.drank + player:getMark("@jiudun_drank") == 0 then
      return room:askToSkillInvoke(player, {
        skill_name = jiudun.name,
        prompt = "#jiudun-invoke",
      })
    else
      local card = room:askToDiscard(player, {
        skill_name = jiudun.name,
        min_num = 1,
        max_num = 1,
        include_equip = false,
        prompt = "#jiudun-card:::"..data.card:toLogString(),
        cancelable = true,
      })
      if #card > 0 then
        event:setCostData(self, {cards = card})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.drank + player:getMark("@jiudun_drank") == 0 then
      player:drawCards(1, jiudun.name)
      if player.dead then return end
      room:useVirtualCard("analeptic", nil, player, player, jiudun.name, true)
    else
      room:throwCard(event:getCostData(self).cards, jiudun.name, player, player)
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      table.insertIfNeed(data.use.nullifiedTargets, player)
    end
  end,
})

jiudun:addEffect(fk.PreCardEffect, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(jiudun.name) and data.to == player and
      data.card.name == "analeptic" and
      not (data.extra_data and data.extra_data.analepticRecover)
  end,
  on_refresh = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    card.skill = Fk.skills["jiudun__analeptic_skill"]
    data.card = card
  end,
})

jiudun:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and player:getMark("@jiudun_drank") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@jiudun_drank")
    data.extra_data = data.extra_data or {}
    data.extra_data.drankBuff = player:getMark("@jiudun_drank")
    player.room:setPlayerMark(player, "@jiudun_drank", 0)
  end,
})

return jiudun
