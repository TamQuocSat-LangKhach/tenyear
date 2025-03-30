local yongjue = fk.CreateSkill {
  name = "ty__yongjue",
}

Fk:loadTranslationTable{
  ["ty__yongjue"] = "勇决",
  [":ty__yongjue"] = "当你于出牌阶段内使用第一张【杀】时，你可以令其不计入使用次数或获得之。",

  ["ty__yongjue_time"] = "此【杀】不计次数",
  ["ty__yongjue_prey"] = "获得%arg",

  ["$ty__yongjue1"] = "能救一个是一个！",
  ["$ty__yongjue2"] = "扶幼主，成霸业！",
}

yongjue:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(yongjue.name) and
      player.phase == Player.Play and data.card.trueName == "slash" and
      player:usedSkillTimes(yongjue.name, Player.HistoryPhase) == 0 then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == player and use.card.trueName == "slash"
      end, Player.HistoryPhase)
      if #use_events == 1 and use_events[1].data == data then
        return not data.extraUse or player.room:getCardArea(data.card) == Card.Processing
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = { "ty__yongjue_time", "ty__yongjue_prey:::"..data.card:toLogString(), "Cancel" }
    local choices = table.simpleClone(all_choices)
    if room:getCardArea(data.card) ~= Card.Processing then
      table.remove(choices, 2)
    end
    if data.extraUse then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = yongjue.name,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "ty__yongjue_time" then
      data.extraUse = true
      player:addCardUseHistory(data.card.trueName, -1)
    else
      room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, yongjue.name)
    end
  end,
})

return yongjue
