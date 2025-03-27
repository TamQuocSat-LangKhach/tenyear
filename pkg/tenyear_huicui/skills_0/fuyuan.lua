local fuyuan = fk.CreateSkill {
  name = "fuyuan"
}

Fk:loadTranslationTable{
  ['fuyuan'] = '扶援',
  ['#fuyuan-invoke'] = '扶援：你可以令 %dest 摸一张牌',
  [':fuyuan'] = '当一名角色成为【杀】的目标后，若其于此【杀】被使用之前的当前回合内未成为过红色牌的目标，你可以令其摸一张牌。',
  ['$fuyuan1'] = '今君困顿，扶援相助。',
  ['$fuyuan2'] = '恤君之患，以相扶援。',
}

fuyuan:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fuyuan.name) and data.card.trueName == "slash" and not target.dead then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local turn_event = use_event:findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      return #room.logic:getEventsByRule(GameEvent.UseCard, 1, function(e)
        if e.id < use_event.id then
          local use = e.data[1]
          if use.card.color == Card.Red and use.tos and table.contains(TargetGroup:getRealTargets(use.tos), target.id) then
            return true
          end
        end
      end, turn_event.id) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = fuyuan.name,
      prompt = "#fuyuan-invoke::" .. target.id
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    target:drawCards(1, fuyuan.name)
  end,
})

return fuyuan
