local liandui = fk.CreateSkill {
  name = "liandui"
}

Fk:loadTranslationTable{
  ['liandui'] = '联对',
  ['#liandui-invoke'] = '联对：你可以发动 %src 的“联对”，令 %dest 摸两张牌',
  [':liandui'] = '当你使用一张牌时，若上一张牌的使用者不为你，你可以令其摸两张牌；其他角色使用一张牌时，若上一张牌的使用者为你，其可以令你摸两张牌。',
  ['$liandui1'] = '以句相联，抒离散之苦。',
  ['$liandui2'] = '以诗相对，颂哀怨之情。',
}

liandui:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(liandui.name) or target.dead then return false end
    local logic = player.room.logic
    local use_event = logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if use_event == nil then return false end
    local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
    local last_find = false
    for i = #events, 1, -1 do
      local e = events[i]
      if e.id == use_event.id then
        last_find = true
      elseif last_find then
        local last_use = e.data[1]
        if player == target then
          if last_use.from ~= player.id then
            event:setCostData(self, last_use.from)
            return true
          end
        else
          if last_use.from == player.id then
            event:setCostData(self, player.id)
            return true
          end
        end
        return false
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = liandui.name,
      prompt = "#liandui-invoke:"..player.id .. ":" .. event:getCostData(self),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(liandui.name)
    room:notifySkillInvoked(player, liandui.name, player == target and "support" or "drawcard")
    room:getPlayerById(event:getCostData(self)):drawCards(2, liandui.name)
  end,
})

return liandui
