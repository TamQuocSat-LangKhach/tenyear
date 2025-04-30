local fengpo = fk.CreateSkill{
  name = "ty__fengpo",
}

Fk:loadTranslationTable{
  ["ty__fengpo"] = "凤魄",
  [":ty__fengpo"] = "当你于回合内首次使用【杀】或【决斗】指定唯一目标后，你可以选择一项：1.摸X张牌，此牌伤害+1；2.摸一张牌，此牌伤害+X"..
  "（X为其<font color='red'>♦</font>牌数）。",

  ["ty__fengpo1"] = "摸X张牌，伤害+1",
  ["ty__fengpo2"] = "摸一张牌，伤害+X",
  ["#ty__fengpo-invoke"] = "凤魄：你可以对 %dest 发动“凤魄”，根据其<font color='red'>♦</font>牌数执行一项",

  ["$ty__fengpo1"] = "飞花鎏金，凤仪枪武。",
  ["$ty__fengpo2"] = "凤栖梧桐，吾归沙场。",
}

fengpo:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fengpo.name) and
      (data.card.trueName == "slash" or data.card.trueName == "duel") and
      data:isOnlyTarget(data.to) and player.room.current == player and
      not table.contains(player:getTableMark("ty__fengpo-turn"), data.card.trueName) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return end
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == player and use.card.trueName == data.card.trueName
      end, Player.HistoryTurn)
      return use_events[1].id == use_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"ty__fengpo1", "ty__fengpo2", "Cancel"},
      skill_name = fengpo.name,
      prompt = "#ty__fengpo-invoke::"..data.to.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {data.to}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = #table.filter(data.to:getCardIds("he"), function (id)
      return Fk:getCardById(id).suit == Card.Diamond
    end)
    if event:getCostData(self).choice == "ty__fengpo1" then
      data.additionalDamage = (data.additionalDamage or 0) + 1
      if n > 0 then
        player:drawCards(n, fengpo.name)
      end
    else
      if n > 0 then
        data.additionalDamage = (data.additionalDamage or 0) + n
      end
      player:drawCards(1, fengpo.name)
    end
  end,
})

return fengpo
