local limu = fk.CreateSkill {
  name = "limu",
}

Fk:loadTranslationTable{
  ["limu"] = "立牧",
  [":limu"] = "出牌阶段，你可以将一张<font color='red'>♦</font>牌当【乐不思蜀】对自己使用，然后回复1点体力；你的判定区有牌时，"..
  "你对攻击范围内的其他角色使用牌无距离次数限制。",

  ["#limu"] = "立牧：将一张<font color='red'>♦</font>牌当【乐不思蜀】对自己使用，然后回复1点体力",

  ["$limu1"] = "今诸州纷乱，当立牧以定！",
  ["$limu2"] = "此非为偏安一隅，但求一方百姓安宁！",
}

limu:addEffect("active", {
  anim_type = "control",
  prompt = "#limu",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:hasDelayedTrick("indulgence") and not table.contains(player.sealedSlots, Player.JudgeSlot)
  end,
  target_filter = Util.FalseFunc,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and Fk:getCardById(to_select).suit == Card.Diamond then
      local card = Fk:cloneCard("indulgence")
      card:addSubcard(to_select)
      return not player:prohibitUse(card) and not player:isProhibited(player, card)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:useVirtualCard("indulgence", effect.cards, player, player, limu.name)
    if player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = 1,
        skillName = limu.name,
      }
    end
  end,
})

limu:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(limu.name) and #player:getCardIds("j") > 0 and
      table.find(data.tos, function (p)
        return player:inMyAttackRange(p)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

limu:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(limu.name) and #player:getCardIds("j") > 0 and to and player:inMyAttackRange(to)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(limu.name) and #player:getCardIds("j") > 0 and to and player:inMyAttackRange(to)
  end,
})

return limu
