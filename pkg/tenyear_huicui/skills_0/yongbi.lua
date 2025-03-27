local yongbi = fk.CreateSkill {
  name = "yongbi"
}

Fk:loadTranslationTable{
  ['yongbi'] = '拥嬖',
  ['#yongbi-prompt'] = '拥嬖：你可将所有手牌交给一名男性角色，且〖媵予〗改为结束阶段也可发动',
  ['@@yongbi'] = '拥嬖',
  ['#yingyu_trigger'] = '拥嬖',
  [':yongbi'] = '限定技，出牌阶段，你可将所有手牌交给一名男性角色，然后〖媵予〗改为结束阶段也可以发动。根据其中牌的花色数量，你与其永久获得以下效果：至少两种，手牌上限+2；至少三种，受到大于1点的伤害时伤害-1。',
  ['$yongbi1'] = '海誓山盟，此生不渝。',
  ['$yongbi2'] = '万千宠爱，幸君怜之。',
}

-- 主动技部分
yongbi:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#yongbi-prompt",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(yongbi.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select).gender == General.Male
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = player:getCardIds(Player.Hand)
    local suits = {}
    for _, id in ipairs(cards) do
      if Fk:getCardById(id, true).suit ~= Card.NoSuit then
        table.insertIfNeed(suits, Fk:getCardById(id, true).suit)
      end
    end
    room:obtainCard(target.id, cards, false, fk.ReasonGive, player.id, yongbi.name)
    if #suits > 1 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 2)
      room:addPlayerMark(target, MarkEnum.AddMaxCards, 2)
    end
    if #suits > 2 then
      room:setPlayerMark(player, "@@yongbi", 1)
      room:setPlayerMark(target, "@@yongbi", 1)
    end
  end,
})

-- 触发技部分
yingyu_trigger = fk.CreateSkill {
  name = "#yingyu_trigger"
}

yingyu_trigger:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yongbi") > 0 and data.damage > 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage - 1
  end,
})

return yongbi
