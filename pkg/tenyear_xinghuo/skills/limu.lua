local limu = fk.CreateSkill {
  name = "limu"
}

Fk:loadTranslationTable{
  ['limu'] = '立牧',
  ['#limu'] = '立牧：选择一张方块牌当【乐不思蜀】对自己使用，然后回复1点体力',
  [':limu'] = '出牌阶段，你可以将一张方块牌当【乐不思蜀】对自己使用，然后回复1点体力；你的判定区有牌时，你对攻击范围内的其他角色使用牌没有次数和距离限制。',
  ['$limu1'] = '今诸州纷乱，当立牧以定！',
  ['$limu2'] = '此非为偏安一隅，但求一方百姓安宁！',
}

-- 主技能
limu:addEffect('active', {
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
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local cards = use.cards
    local card = Fk:cloneCard("indulgence")
    card:addSubcards(cards)
    room:useCard{
      from = use.from,
      tos = {{use.from}},
      card = card,
    }
    if player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = 1,
        skillName = limu.name
      }
    end
  end,
})

-- 刷新效果
limu:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return player == target and #player:getCardIds(Player.Judge) > 0 and player:hasSkill(limu.name) and
      table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return player:inMyAttackRange(player.room:getPlayerById(pid))
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

-- 目标修正效果
limu:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(limu.name) and #player:getCardIds(Player.Judge) > 0 and to and player:inMyAttackRange(to)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(limu.name) and #player:getCardIds(Player.Judge) > 0 and to and player:inMyAttackRange(to)
  end,
})

return limu
