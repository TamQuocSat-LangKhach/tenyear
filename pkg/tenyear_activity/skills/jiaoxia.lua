local jiaoxia = fk.CreateSkill {
  name = "jiaoxia"
}

Fk:loadTranslationTable{
  ['jiaoxia'] = '狡黠',
  ['#jiaoxia-invoke'] = '狡黠：你可以令本阶段你的手牌均视为【杀】，且结算后你可以使用原卡牌！',
  ['#jiaoxia-use'] = '狡黠：你可以使用【%arg】',
  ['@@jiaoxia-phase'] = '狡黠',
  ['#jiaoxia_filter'] = '狡黠',
  [':jiaoxia'] = '出牌阶段开始时，你可以令本阶段你的手牌均视为【杀】。若你以此法使用的【杀】造成了伤害，此【杀】结算后你可以视为使用原卡牌（有次数限制）。出牌阶段，你对每名角色使用第一张【杀】无距离和次数限制。',
  ['$jiaoxia1'] = '暗剑匿踪，现时必捣黄龙！',
  ['$jiaoxia2'] = '袖中藏刃，欲取诸君之头！',
}

-- TriggerSkill effects
jiaoxia:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return player.phase == Player.Play and player:hasSkill(jiaoxia.name)
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {skill_name = jiaoxia.name, prompt = "#jiaoxia-invoke"})
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "@@jiaoxia-phase", 1)
    player:filterHandcards()
  end,
})

jiaoxia:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if table.contains(data.card.skillNames, "jiaoxia") and data.damageDealt then
      local card = Fk:getCardById(data.card:getEffectiveId())
      return player:canUse(card) and not player:prohibitUse(card) and player.room:getCardArea(card) == Card.Processing
    end
  end,
  on_use = function(self, event, target, player, data)
    local ids = Card:getIdList(data.card)
    player.room:askToUseRealCard(player, {pattern = ids, skill_name = jiaoxia.name, prompt = "#jiaoxia-use:::" .. Fk:getCardById(ids[1]):toLogString(), expand_pile = ids})
  end,
})

jiaoxia:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return data.card.trueName == "slash" and player.phase == Player.Play and
      not table.contains(player:getTableMark("jiaoxia_target-phase"), data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "jiaoxia_target-phase", data.to)
  end,
})

-- Refresh effects
jiaoxia:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    if player == target and data.card.trueName == "slash" and player.phase == Player.Play and player:hasSkill(jiaoxia.name) then
      local mark = player:getTableMark("jiaoxia_target-phase")
      return table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return not table.contains(mark, pid)
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

-- TargetModSkill effect
jiaoxia:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(jiaoxia.name) and card and card.trueName == "slash" and to and
      not table.contains(player:getTableMark("jiaoxia_target-phase"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(jiaoxia.name) and card and card.trueName == "slash" and to and
      not table.contains(player:getTableMark("jiaoxia_target-phase"), to.id)
  end,
})

-- FilterSkill effect
jiaoxia:addEffect("filter", {
  card_filter = function(self, player, to_select)
    return player:hasSkill(jiaoxia.name) and player:getMark("@@jiaoxia-phase") > 0 and
      table.contains(player.player_cards[Player.Hand], to_select.id)
  end,
  view_as = function(self, player, to_select)
    local card = Fk:cloneCard("slash", to_select.suit, to_select.number)
    card.skillName = jiaoxia.name
    return card
  end,
})

return jiaoxia
