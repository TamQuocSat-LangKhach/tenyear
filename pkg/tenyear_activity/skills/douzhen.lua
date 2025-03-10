local douzhen = fk.CreateSkill {
  name = "douzhen"
}

Fk:loadTranslationTable{
  ['douzhen'] = '斗阵',
  ['#douzhen_filter'] = '斗阵',
  [':douzhen'] = '转换技，锁定技，你的回合内，阳：你的黑色基本牌视为【决斗】，且使用时获得目标一张牌；阴：你的红色基本牌视为【杀】，且使用时无次数限制。',
  ['$douzhen1'] = '擂鼓击柝，庆我兄弟凯旋。',
  ['$douzhen2'] = '匹夫欺我江东无人乎。',
}

-- TriggerSkill
douzhen:addEffect(fk.CardUsing, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(douzhen.name) and 
      not data.card:isVirtual() and table.contains(data.card.skillNames, douzhen.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.trueName == "duel" then
      local targets = TargetGroup:getRealTargets(data.tos)
      room:doIndicate(player.id, targets)
      for _, id in ipairs(targets) do
        local p = room:getPlayerById(id)
        if not (p.dead or p:isNude()) then
          local c = room:askToChooseCard(player, { target = p, flag = "he", skill_name = douzhen.name })
          room:obtainCard(player, c, false, fk.ReasonPrey)
        end
        if player.dead then return end
      end
    end
  end,
})

douzhen:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and not data.card:isVirtual() and table.contains(data.card.skillNames, douzhen.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

-- FilterSkill
douzhen:addEffect('filter', {
  card_filter = function(self, player, card, selected)
    if player:hasSkill(douzhen.name) and player.phase ~= Player.NotActive and card.type == Card.TypeBasic and 
      table.contains(player.player_cards[Player.Hand], card.id) then
      if player:getSwitchSkillState("douzhen", false) == fk.SwitchYang then
        return card.color == Card.Black
      else
        return card.color == Card.Red
      end
    end
  end,
  view_as = function(self, player, cards)
    local name = "slash"
    if player:getSwitchSkillState("douzhen", false) == fk.SwitchYang then
      name = "duel"
    end
    local c = Fk:cloneCard(name, cards[1].suit, cards[1].number)
    c.skillName = douzhen.name
    return c
  end,
})

-- TargetModSkill
douzhen:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card)
    return card and card.trueName == "slash" and table.contains(card.skillNames, douzhen.name) and scope == Player.HistoryPhase
  end,
})

return douzhen
