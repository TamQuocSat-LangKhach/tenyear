local qingshi = fk.CreateSkill {
  name = "qingshi",
}

Fk:loadTranslationTable{
  ["qingshi"] = "情势",
  [":qingshi"] = "当你于出牌阶段内使用牌时（每种牌名每回合限一次），若手牌中有同名牌，你可以选择一项：1.令此牌对其中一个目标造成的伤害值+1；"..
  "2.令任意名其他角色各摸一张牌；3.摸三张牌，然后此技能本回合失效。",

  ["qingshi-turn"] = "情势",
  ["qingshi1"] = "令此牌对其中一个目标伤害+1",
  ["qingshi2"] = "令任意名其他角色各摸一张牌",
  ["qingshi3"] = "摸三张牌，然后此技能本回合失效",
  ["#qingshi-invoke"] = "情势：请选择一项（当前使用牌为%arg）",
  ["#qingshi1-choose"] = "情势：令%arg对其中一名目标造成伤害+1",
  ["#qingshi2-choose"] = "情势：令任意名其他角色各摸一张牌",

  ["$qingshi1"] = "兵者，行霸道之势，彰王道之实。",
  ["$qingshi2"] = "将为军魂，可因势而袭，其有战无类。",
}

qingshi:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingshi.name) and player.phase == Player.Play and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).trueName == data.card.trueName
      end) and
      not table.contains(player:getTableMark("qingshi-turn"), data.card.trueName)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {"qingshi1", "qingshi2", "qingshi3", "Cancel"}
    local choices = table.simpleClone(all_choices)
    if #data.tos == 0 then
      table.remove(choices, 1)
    end
    if #room:getOtherPlayers(player, false) == 0 then
      table.removeOne(choices, "qingshi2")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = qingshi.name,
      prompt = "#qingshi-invoke:::"..data.card:toLogString(),
      all_choices = all_choices,
    })
    if choice == "qingshi1" then
      local to = room:askToChoosePlayers(player, {
        targets = data.tos,
        min_num = 1,
        max_num = 1,
        prompt = "#qingshi1-choose:::"..data.card:toLogString(),
        skill_name = qingshi.name,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to, choice = choice})
        return true
      end
    elseif choice == "qingshi2" then
      local tos = room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 9,
        prompt = "#qingshi2-choose:::"..data.card:toLogString(),
        skill_name = qingshi.name,
      })
      if #tos > 0 then
        room:sortByAction(tos)
        event:setCostData(self, {tos = tos, choice = choice})
        return true
      end
    elseif choice == "qingshi3" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "qingshi-turn", data.card.trueName)
    if event:getCostData(self).choice == "qingshi1" then
      data.extra_data = data.extra_data or {}
      data.extra_data.qingshi_data = data.extra_data.qingshi_data or {}
      table.insert(data.extra_data.qingshi_data, {player, event:getCostData(self).tos[1]})
    elseif event:getCostData(self).choice == "qingshi2" then
      local tos = event:getCostData(self).tos
      for _, p in ipairs(tos) do
        if not p.dead then
          p:drawCards(1, qingshi.name)
        end
      end
    elseif event:getCostData(self).choice == "qingshi3" then
      room:invalidateSkill(player, qingshi.name, "-turn")
      player:drawCards(3, qingshi.name)
    end
  end,
})

qingshi:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card and player.room.logic:damageByCardEffect() then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event == nil then return end
      local use = use_event.data
      if use.extra_data and use.extra_data.qingshi_data then
        return table.find(use.extra_data.qingshi_data, function (info)
          return info[1] == player and info[2] == data.to
        end)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return qingshi
