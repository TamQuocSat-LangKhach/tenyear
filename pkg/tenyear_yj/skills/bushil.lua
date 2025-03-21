local bushil = fk.CreateSkill {
  name = "bushil"
}

Fk:loadTranslationTable{
  ["bushil"] = "卜筮",
  ["#bushil-invoke"] = "卜筮：是否重新分配“卜筮”的花色？",
  ["#bushil-discard"] = "卜筮：你可以弃置一张手牌令%arg对你无效",
  ["@bushil"] = "卜筮",
  [":bushil"] = "你使用♠牌无次数限制；<br>你使用或打出<font color='red'>♥</font>牌后，摸一张牌；<br>当你成为♣牌的目标后，你可以弃置一张手牌令此牌对你无效；<br>结束阶段，你获得一张<font color='red'>♦</font>牌。<br>准备阶段，你可以将以上四种花色重新分配。",
  ["$bushil1"] = "论演玄意，以筮辄验。",
  ["$bushil2"] = "手不释书，好研经卷。",
}

bushil:addEffect({fk.CardUseFinished, fk.CardRespondFinished, fk.TargetConfirmed, fk.EventPhaseStart}, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(bushil.name) then
      if event == fk.CardUseFinished or event == fk.CardRespondFinished then
        return player:getMark("bushil2") == "log_"..data.card:getSuitString()
      elseif event == fk.TargetConfirmed then
        return data.card.type ~= Card.TypeEquip and player:getMark("bushil3") == "log_"..data.card:getSuitString() and not player:isKongcheng()
      elseif event == fk.EventPhaseStart then
        return player.phase == Player.Start or player.phase == Player.Finish
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart and player.phase == Player.Start then
      return player.room:askToSkillInvoke(player, {
        skill_name = bushil.name,
        prompt = "#bushil-invoke",
      })
    elseif event == fk.TargetConfirmed then
      local card = player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = bushil.name,
        cancelable = true,
        pattern = ".",
        prompt = "#bushil-discard:::"..data.card:toLogString(),
      })
      if #card > 0 then
        event:setCostData(self, card)
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(bushil.name)
    if event == fk.EventPhaseStart and player.phase == Player.Start then
      room:notifySkillInvoked(player, bushil.name, "special")
      local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
      for i = 1, 4, 1 do
        local choices = table.map(suits, Util.TranslateMapper)
        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = bushil.name,
          prompt = "#bushil"..i.."-choice",
        })
        local str = suits[table.indexOf(choices, choice)]
        table.removeOne(suits, str)
        room:setPlayerMark(player, "bushil"..i, str)
        room:setPlayerMark(player, "@bushil", string.format("%s-%s-%s-%s",
          Fk:translate(player:getMark("bushil1")),
          Fk:translate(player:getMark("bushil2")),
          Fk:translate(player:getMark("bushil3")),
          Fk:translate(player:getMark("bushil4"))))
      end
    elseif event == fk.CardUseFinished or event == fk.CardRespondFinished then
      room:notifySkillInvoked(player, bushil.name, "drawcard")
      player:drawCards(1, bushil.name)
    elseif event == fk.TargetConfirmed then
      room:notifySkillInvoked(player, bushil.name, "defensive")
      local cost_data = event:getCostData(self)
      room:throwCard(cost_data, bushil.name, player, player)
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      else
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    elseif event == fk.EventPhaseStart and player.phase == Player.Finish then
      room:notifySkillInvoked(player, bushil.name, "drawcard")
      local card = room:getCardsFromPileByRule(".|.|"..string.sub(player:getMark("bushil4"), 5))
      if #card > 0 then
        room:moveCards({
          ids = card,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = bushil.name,
        })
      end
    end
  end,
})

bushil:addEffect({fk.PreCardUse, fk.EventAcquireSkill, fk.EventLoseSkill}, {
  can_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      return player:hasSkill(bushil.name) and player == target and player:getMark("bushil1") == "log_"..data.card:getSuitString()
    else
      return target == player and data == bushil
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PreCardUse then
      data.extraUse = true
    elseif event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "bushil1", "log_spade")
      room:setPlayerMark(player, "bushil2", "log_heart")
      room:setPlayerMark(player, "bushil3", "log_club")
      room:setPlayerMark(player, "bushil4", "log_diamond")
      room:setPlayerMark(player, "@bushil", string.format("%s-%s-%s-%s",
        Fk:translate(player:getMark("bushil1")),
        Fk:translate(player:getMark("bushil2")),
        Fk:translate(player:getMark("bushil3")),
        Fk:translate(player:getMark("bushil4"))))
    else
      for _, mark in ipairs({"bushil1", "bushil2", "bushil3", "bushil4", "@bushil"}) do
        room:setPlayerMark(player, mark, 0)
      end
    end
  end,
})

local bushil_targetmod = fk.CreateTargetModSkill{
  name = "#bushil_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and player:hasSkill(bushil.name) and player:getMark("bushil1") == "log_"..card:getSuitString()
  end,
}

return bushil
