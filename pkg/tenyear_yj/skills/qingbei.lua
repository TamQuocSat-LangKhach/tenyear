local qingbei = fk.CreateSkill {
  name = "qingbei",
}

Fk:loadTranslationTable{
  ["qingbei"] = "擎北",
  [":qingbei"] = "每轮开始时，你可以选择任意种花色令你本轮无法使用，然后本轮你使用一张有花色的手牌后，摸本轮〖擎北〗选择过的花色数的牌。",

  ["@qingbei-round"] = "擎北",
  ["#qingbei-choice"] = "擎北：选择你本轮不能使用的花色",

  ["$qingbei1"] = "待追上那司马懿，定教他没好果子吃！",
  ["$qingbei2"] = "身若不周，吾一人可作擎北之柱。",
}

qingbei:addEffect(fk.RoundStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qingbei.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
    local choices = room:askToChoices(player, {
      choices = suits,
      min_num = 1,
      max_num = 4,
      skill_name = qingbei.name,
      prompt = "#qingbei-choice",
      cancelable = true,
    })
    if #choices > 0 then
      event:setCostData(self, {choice = choices})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@qingbei-round", event:getCostData(self).choice)
  end,
})

qingbei:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingbei.name) and
      data.card.suit ~= Card.NoSuit and player:getMark("@qingbei-round") ~= 0 and
      data:IsUsingHandcard(player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(#player:getMark("@qingbei-round"), qingbei.name)
  end,
})

qingbei:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("@qingbei-round") ~= 0 and card and table.contains(player:getMark("@qingbei-round"), card:getSuitString(true))
  end,
})

return qingbei
