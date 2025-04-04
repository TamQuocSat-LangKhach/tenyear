local yongbi = fk.CreateSkill {
  name = "yongbi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["yongbi"] = "拥嬖",
  [":yongbi"] = "限定技，出牌阶段，你可将所有手牌交给一名男性角色，然后〖媵予〗改为结束阶段也可以发动。根据其中牌的花色数量，"..
  "你与其永久获得以下效果：至少两种，手牌上限+2；至少三种，受到大于1点的伤害时伤害-1。",

  ["#yongbi"] = "拥嬖：将所有手牌交给一名男性角色，你与其永久获得效果，“媵予”改为结束阶段也可发动",
  ["@@yongbi"] = "拥嬖",

  ["$yongbi1"] = "海誓山盟，此生不渝。",
  ["$yongbi2"] = "万千宠爱，幸君怜之。",
}

yongbi:addEffect("active", {
  anim_type = "support",
  prompt = "#yongbi",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedEffectTimes(yongbi.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:isMale()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local suits = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    table.removeOne(suits, Card.NoSuit)
    room:obtainCard(target, player:getCardIds("h"), false, fk.ReasonGive, player, yongbi.name)
    if #suits > 1 then
      if not player.dead then
        room:addPlayerMark(player, MarkEnum.AddMaxCards, 2)
      end
      if not target.dead then
        room:addPlayerMark(target, MarkEnum.AddMaxCards, 2)
      end
    end
    if #suits > 2 then
      if not player.dead then
        room:setPlayerMark(player, "@@yongbi", 1)
      end
      if not target.dead then
        room:setPlayerMark(target, "@@yongbi", 1)
      end
    end
  end,
})

yongbi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yongbi") > 0 and data.damage > 1
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
  end,
})

return yongbi
