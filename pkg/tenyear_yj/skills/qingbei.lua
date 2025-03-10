local qingbei = fk.CreateSkill {
  name = "qingbei"
}

Fk:loadTranslationTable{
  ['qingbei'] = '擎北',
  ['@qingbei-round'] = '擎北',
  ['#qingbei-choice'] = '擎北：选择你本轮不能使用的花色',
  [':qingbei'] = '每轮开始时，你可以选择任意种花色令你本轮无法使用，然后本轮你使用一张有花色的手牌后，摸本轮〖擎北〗选择过的花色数的牌。',
  ['$qingbei1'] = '待追上那司马懿，定教他没好果子吃！',
  ['$qingbei2'] = '身若不周，吾一人可作擎北之柱。',
}

-- RoundStart and CardUseFinished trigger effect
qingbei:addEffect(fk.RoundStart, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(qingbei.name) then
      return true
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
    local choices = room:askToChoices(player, {
      choices = suits,
      min_num = 1,
      max_num = 4,
      skill_name = qingbei.name,
      prompt = "#qingbei-choice",
      cancelable = true
    })
    if #choices > 0 then
      event:setCostData(skill, choices)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local data = event:getCostData(skill)
    player.room:setPlayerMark(player, "@qingbei-round", data)
  end,
})

qingbei:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qingbei.name) and target == player and data.card.suit ~= Card.NoSuit and player:getMark("@qingbei-round") ~= 0 then
      return U.IsUsingHandcard(player, data)
    end
  end,
  on_use = function(self, event, target, player)
    local mark = player:getMark("@qingbei-round")
    player:drawCards(#mark, qingbei.name)
  end,
})

-- ProhibitSkill effect
qingbei:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    return player:getMark("@qingbei-round") ~= 0 and table.contains(player:getMark("@qingbei-round"), card:getSuitString(true))
  end,
})

return qingbei
