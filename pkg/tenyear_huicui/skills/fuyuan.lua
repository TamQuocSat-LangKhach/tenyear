local fuyuan = fk.CreateSkill {
  name = "fuyuan",
}

Fk:loadTranslationTable{
  ["fuyuan"] = "扶援",
  [":fuyuan"] = "当一名角色成为【杀】的目标后，若其本回合此前未成为过红色牌的目标，你可以令其摸一张牌。",

  ["#fuyuan-invoke"] = "扶援：你可以令 %dest 摸一张牌",

  ["$fuyuan1"] = "今君困顿，扶援相助。",
  ["$fuyuan2"] = "恤君之患，以相扶援。",
}

fuyuan:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fuyuan.name) and data.card.trueName == "slash" and not target.dead then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return end
      return #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        if e.id < use_event.id then
          local use = e.data
          return use.card.color == Card.Red and table.contains(use.tos, target)
        end
      end, Player.HistoryTurn) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = fuyuan.name,
      prompt = "#fuyuan-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, fuyuan.name)
  end,
})

return fuyuan
