local yuxian = fk.CreateSkill {
  name = "yuxian",
}

Fk:loadTranslationTable{
  ["yuxian"] = "育贤",
  [":yuxian"] = "记录你于出牌阶段内使用的前四张手牌的花色直到你的下个回合开始；"..
  "当其他角色于其回合内使用前四张牌时，若此牌与你记录的对应位置的花色相同，你可以与其各摸一张牌。",

  ["#yuxian-invoke"] = "育贤：是否与 %dest 各摸一张牌？",
  ["@yuxian"] = "育贤",

  ["$yuxian1"] = "建业风寒，登儿益常添衣。",
  ["$yuxian2"] = "妾不为汝妻，尚不能为人母乎？",
}

yuxian:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuxian.name) and data.card.suit ~= Card.NoSuit then
      if target == player then
        return player.phase == Player.Play and #player:getTableMark("@yuxian") < 4 and
          data.card.suit ~= Card.NoSuit and data:IsUsingHandcard(player)
      elseif target == player.room.current and player:getMark("@yuxian") ~= 0 and not target.dead then
        local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 4, function(e)
          local use = e.data
          return use.from == target
        end, Player.HistoryTurn)
        local index = table.indexOf(use_events, player.room.logic:getCurrentEvent())
        return index ~= -1 and data.card:getSuitString(true) == player:getTableMark("@yuxian")[index]
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if target == player then
      event:setCostData(self, nil)
      return true
    elseif player.room:askToSkillInvoke(player, {
      skill_name = yuxian.name,
      prompt = "#yuxian-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if player == target then
      player.room:addTableMark(player, "@yuxian", data.card:getSuitString(true))
    else
      player:drawCards(1, yuxian.name)
      if not target.dead then
        target:drawCards(1, yuxian.name)
      end
    end
  end,
})

yuxian:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@yuxian", 0)
  end,
})

yuxian:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@yuxian", 0)
end)

return yuxian
