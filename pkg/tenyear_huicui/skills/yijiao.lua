local yijiao = fk.CreateSkill {
  name = "yijiao",
}

Fk:loadTranslationTable{
  ["yijiao"] = "异教",
  [":yijiao"] = "出牌阶段限一次，你可以选择一名其他角色并选择一个1~4的数字，该角色获得十倍的“异”标记；有“异”标记的角色结束阶段，"..
  "若其本回合使用牌的点数之和：<br>1.小于“异”标记数，其随机弃置一至三张手牌；<br>2.等于“异”标记数，你摸两张牌且其于本回合结束后"..
  "进行一个额外的回合；<br>3.大于“异”标记数，你摸三张牌。",

  ["#yijiao"] = "异教：令一名角色获得你选择数字10倍的“异”标记，根据其回合使用牌点数执行效果",
  ["@yijiao"] = "异",
  ["@yijiao-turn"] = "异",

  ["$yijiao1"] = "攻乎异教，斯害也已。",
  ["$yijiao2"] = "非我同盟，其心必异。",
}

yijiao:addEffect("active", {
  anim_type = "support",
  prompt = "#yijiao",
  card_num = 0,
  target_num = 1,
  interaction = UI.Spin { from = 1, to = 4 },
  can_use = function(self, player)
    return player:usedEffectTimes(yijiao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and to_select:getMark(yijiao.name) == 0
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    room:addPlayerMark(target, yijiao.name, 10 * self.interaction.data)
    room:setPlayerMark(target, "@yijiao", target:getMark(yijiao.name))
    room:setPlayerMark(target, "yijiao_src", effect.from.id)
  end,
})

yijiao:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and not player.dead and target:getMark("yijiao_src-turn") == player.id
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("yijiao_count-turn") - target:getMark("yijiao-turn")
    if n < 0 then
      if not target:isKongcheng() then
        local cards = table.filter(target:getCardIds("h"), function (id)
          return not target:prohibitDiscard(id)
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
      player:drawCards(2, yijiao.name)
      if not target.dead then
        target:gainAnExtraTurn(true)
      end
    else
      player:drawCards(3, yijiao.name)
    end
  end,
})
yijiao:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark(yijiao.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "yijiao-turn", player:getMark(yijiao.name))
    room:setPlayerMark(player, yijiao.name, 0)
    room:setPlayerMark(player, "yijiao_src-turn", player:getMark("yijiao_src"))
    room:setPlayerMark(player, "yijiao_src", 0)
    room:setPlayerMark(player, "@yijiao-turn", string.format("%d/%d", player:getMark("yijiao-turn"), 0))
    room:setPlayerMark(player, "@yijiao", 0)
  end,
})

yijiao:addEffect(fk.CardUsing, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("yijiao_src-turn") ~= 0 and data.card.number > 0 and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "yijiao_count-turn", data.card.number)
    room:setPlayerMark(player, "@yijiao-turn", string.format("%d/%d", player:getMark("yijiao-turn"), player:getMark("yijiao_count-turn")))
  end,
})

yijiao:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if p:getMark("yijiao_src") == player.id then
      room:setPlayerMark(p, "yijiao_src", 0)
      room:setPlayerMark(p, "@yijiao", 0)
      room:setPlayerMark(p, yijiao.name, 0)
    end
    if p:getMark("yijiao_src-turn") == player.id then
      room:setPlayerMark(p, "yijiao_src-turn", 0)
      room:setPlayerMark(p, "@yijiao-turn", 0)
      room:setPlayerMark(p, "yijiao-turn", 0)
      room:setPlayerMark(p, "yijiao_count-turn", 0)
    end
  end
end)

return yijiao
