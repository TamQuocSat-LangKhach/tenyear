local qianzheng = fk.CreateSkill {
  name = "qianzheng"
}

Fk:loadTranslationTable{
  ['qianzheng'] = '愆正',
  ['#qianzheng1-card'] = '愆正：你可以重铸两张牌，若均不为%arg，结算后获得%arg2',
  ['#qianzheng2-card'] = '愆正：你可以重铸两张牌',
  ['#qianzheng-invoke'] = '愆正：你可以获得此%arg',
  [':qianzheng'] = '每回合限两次，当你成为其他角色使用普通锦囊牌或【杀】的目标时，你可以重铸两张牌，若这两张牌与使用牌类型均不同，此牌结算后进入弃牌堆时你可以获得之。',
  ['$qianzheng1'] = '悔往昔之种种，恨彼时之切切。',
  ['$qianzheng2'] = '罪臣怀咎难辞，有愧国恩。',
}

qianzheng:addEffect(fk.TargetConfirming, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.from ~= player.id and
      (data.card:isCommonTrick() or data.card.trueName == "slash") and #player:getCardIds{Player.Hand, Player.Equip} > 1 and
      player:usedSkillTimes(qianzheng.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#qianzheng1-card:::"..data.card:getTypeString()..":"..data.card:toLogString()
    if data.card:isVirtual() and not data.card:getEffectiveId() then
      prompt = "#qianzheng2-card"
    end
    local cards = player.room:askToCards(player, {
      min_num = 2,
      max_num = 2,
      pattern = ".",
      prompt = prompt,
      skill_name = qianzheng.name,
      cancelable = true,
    })
    if #cards == 2 then
      event:setCostData(skill, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(skill)
    if Fk:getCardById(cards[1]).type ~= data.card.type and Fk:getCardById(cards[2]).type ~= data.card.type then
      data.extra_data = data.extra_data or {}
      data.extra_data.qianzheng = player.id
    end
    room:recastCard(cards, player, qianzheng.name)
  end,
})

qianzheng:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.qianzheng and data.extra_data.qianzheng == player.id and
      player.room:getCardArea(data.card) == Card.Processing and not player.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = qianzheng.name,
      prompt = "#qianzheng-invoke:::"..data.card:toLogString()
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
  end,
})

return qianzheng
