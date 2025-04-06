local yuandi = fk.CreateSkill {
  name = "yuandi",
}

Fk:loadTranslationTable{
  ["yuandi"] = "元嫡",
  [":yuandi"] = "其他角色于其出牌阶段使用第一张牌时，若此牌没有指定除其以外的角色为目标，你可以选择一项：1.弃置其一张手牌；2.你与其各摸一张牌。",

  ["yuandi_draw"] = "你与%dest各摸一张牌",
  ["yuandi_discard"] = "弃置%dest一张手牌",

  ["$yuandi1"] = "此生与君为好，共结连理。",
  ["$yuandi2"] = "结发元嫡，其情唯衷孙郎。",
}

yuandi:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuandi.name) and target ~= player and target.phase == Player.Play and
      (#data.tos == 0 or data:isOnlyTarget(target)) then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == target
      end, Player.HistoryPhase)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = { "yuandi_discard::"..target.id, "yuandi_draw::"..target.id, "Cancel" }
    local choices = table.simpleClone(all_choices)
    if target:isKongcheng() then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = yuandi.name,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice:startsWith("yuandi_discard") then
      local id = room:askToChooseCard(player, {
        target = target,
        flag = "h",
        skill_name = yuandi.name,
      })
      room:throwCard(id, yuandi.name, target, player)
    else
      player:drawCards(1, yuandi.name)
      if not target.dead then
        target:drawCards(1, yuandi.name)
      end
    end
  end,
})

return yuandi
