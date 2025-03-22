local bushi = fk.CreateSkill {
  name = "bushil",
  dynamic_desc = function (self, player)
    local str = "bushil_inner"
    for i = 1, 4, 1 do
      str = str..":"..Fk:translate(player:getMark("bushil"..i))
    end
    return str
  end,
}

Fk:loadTranslationTable{
  ["bushil"] = "卜筮",
  [":bushil"] = "你使用♠牌无次数限制；<br>你使用或打出<font color='red'>♥</font>牌后，摸一张牌；<br>当你成为♣牌的目标后，"..
  "你可以弃置一张手牌令此牌对你无效；<br>结束阶段，你获得一张<font color='red'>♦</font>牌。<br>准备阶段，你可以将以上四种花色重新分配。",

  [":bushil_inner"] = "你使用{1}牌无次数限制；<br>你使用或打出{2}牌后，摸一张牌；<br>当你成为{3}牌的目标后，"..
  "你可以弃置一张手牌令此牌对你无效；<br>结束阶段，你获得一张{4}牌。<br>准备阶段，你可以将以上四种花色重新分配。",

  ["#bushil-invoke"] = "卜筮：是否重新分配“卜筮”的花色？",
  ["#bushil1-choice"] = "卜筮：使用此花色牌无次数限制",
  ["#bushil2-choice"] = "卜筮：使用或打出此花色牌后摸一张牌",
  ["#bushil3-choice"] = "卜筮：成为此花色牌目标后可弃置一张手牌对你无效",
  ["#bushil-discard"] = "卜筮：你可以弃置一张手牌令%arg对你无效",

  ["$bushil1"] = "论演玄意，以筮辄验。",
  ["$bushil2"] = "手不释书，好研经卷。",
}

local spec = {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(bushi.name) and
      player:getMark("bushil2") == "log_"..data.card:getSuitString()
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, bushi.name)
  end,
}

bushi:addEffect(fk.CardUseFinished, spec)
bushi:addEffect(fk.CardRespondFinished, spec)

bushi:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(bushi.name) and
      data.card.type ~= Card.TypeEquip and not player:isKongcheng() and
      player:getMark("bushil3") == "log_"..data.card:getSuitString()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = bushi.name,
      cancelable = true,
      prompt = "#bushil-discard:::"..data.card:toLogString(),
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, bushi.name, player, player)
    if data.card.sub_type == Card.SubtypeDelayedTrick then
      data:cancelTarget(player)
    else
      data.use.nullifiedTargets = data.use.nullifiedTargets or data.use.nullifiedTargets
      table.insertIfNeed(data.use.nullifiedTargets, player)
    end
  end,
})

bushi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(bushi.name) and
      (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function (self, event, target, player, data)
    if player.phase == Player.Start then
      return player.room:askToSkillInvoke(player, {
        skill_name = bushi.name,
        prompt = "#bushil-invoke",
      })
    else
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
      for i = 1, 4, 1 do
        local choices = table.map(suits, Util.TranslateMapper)
        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = bushi.name,
          prompt = "#bushil"..i.."-choice",
          all_choices = suits,
        })
        local str = suits[table.indexOf(choices, choice)]
        table.removeOne(suits, str)
        room:setPlayerMark(player, "bushil"..i, str)
      end
    elseif player.phase == Player.Finish then
      local card = room:getCardsFromPileByRule(".|.|"..string.sub(player:getMark("bushil4"), 5))
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, bushi.name, nil, false, player)
      end
    end
  end,
})

bushi:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(bushi.name) and
      player:getMark("bushil1") == "log_"..data.card:getSuitString()
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})
bushi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and player:hasSkill(bushi.name) and player:getMark("bushil1") == "log_"..card:getSuitString()
  end,
})

bushi:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  room:setPlayerMark(player, "bushil1", "log_spade")
  room:setPlayerMark(player, "bushil2", "log_heart")
  room:setPlayerMark(player, "bushil3", "log_club")
  room:setPlayerMark(player, "bushil4", "log_diamond")
end)

return bushi
