local yijiao = fk.CreateSkill {
  name = "yijiao"
}

Fk:loadTranslationTable{
  ['yijiao'] = '异教',
  ['@yijiao'] = '异',
  ['#yijiao_record'] = '异教',
  [':yijiao'] = '出牌阶段限一次，你可以选择一名其他角色并选择一个1~4的数字，该角色获得十倍的“异”标记；有“异”标记的角色结束阶段，若其本回合使用牌的点数之和：<br>1.小于“异”标记数，其随机弃置一至三张手牌；<br>2.等于“异”标记数，你摸两张牌且其于本回合结束后进行一个额外的回合；<br>3.大于“异”标记数，你摸三张牌。',
  ['$yijiao1'] = '攻乎异教，斯害也已。',
  ['$yijiao2'] = '非我同盟，其心必异。',
}

yijiao:addEffect('active', {
  name = "yijiao",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = 4,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(yijiao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select):getMark("yijiao1") == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    if not skill.interaction.data then 
      skill.interaction.data = 1 
    end  --for AI
    room:addPlayerMark(target, "yijiao1", 10 * skill.interaction.data)
    room:setPlayerMark(target, "@yijiao", target:getMark("yijiao1"))
    room:setPlayerMark(target, "yijiao_src", effect.from)
  end,
})

yijiao:addEffect(fk.EventPhaseStart, {
  name = "#yijiao_record",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and not player.dead and target:getMark("yijiao_src") == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("yijiao2") - target:getMark("yijiao1")
    room:doIndicate(player.id, {target.id})
    if n < 0 then
      player:broadcastSkillInvoke(yijiao.name, 1)
      room:notifySkillInvoked(player, yijiao.name, "control")
      if not target:isKongcheng() then
        local cards = table.filter(target.player_cards[Player.Hand], function (id)
          return not target:prohibitDiscard(Fk:getCardById(id))
        end)
        if #cards > 0 then
          local x = math.random(1, math.min(3, #cards))
          if x < #cards then
            cards = table.random(cards, x)
          end
          room:throwCard(cards, yijiao.name, target, target)
        end
      end
    elseif n == 0 then
      player:broadcastSkillInvoke(yijiao.name, 2)
      room:notifySkillInvoked(player, yijiao.name, "support")
      player:drawCards(2, yijiao.name)
      target:gainAnExtraTurn(true)
    else
      player:broadcastSkillInvoke(yijiao.name, 2)
      room:notifySkillInvoked(player, yijiao.name, "drawcard")
      player:drawCards(3, yijiao.name)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return target == player and player:getMark("yijiao1") ~= 0 and player.phase ~= Player.NotActive and data.card.number > 0
    elseif event == fk.AfterTurnEnd then
      return target == player and player:getMark("yijiao1") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(player, "yijiao2", data.card.number)
      room:setPlayerMark(player, "@yijiao", string.format("%d/%d", target:getMark("yijiao1"), target:getMark("yijiao2")))
    elseif event == fk.AfterTurnEnd then
      room:setPlayerMark(player, "yijiao1", 0)
      room:setPlayerMark(player, "yijiao2", 0)
      room:setPlayerMark(player, "@yijiao", 0)
      room:setPlayerMark(player, "yijiao_src", 0)
    end
  end,
})

return yijiao
