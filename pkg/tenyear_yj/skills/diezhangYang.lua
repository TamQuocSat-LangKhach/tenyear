local diezhang = fk.CreateSkill {
  name = "diezhangYang",
}

Fk:loadTranslationTable{
  ["diezhangYang"] = "叠嶂",
  [":diezhangYang"] = "每回合限一次，当你使用牌被其他角色抵消后，你可以弃置一张牌视为对其使用两张【杀】。",

  ["#diezhangYang-invoke"] = "叠嶂：你可以弃置一张牌，视为对 %dest 使用两张【杀】",
}

diezhang:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(diezhang.name) and target == player and data.to ~= player and not data.to.dead and
      not player:isProhibited(data.to, Fk:cloneCard("slash")) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return end
      local yes = false
      player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.responseToEvent == data then
          if use.from ~= player then
            yes = true
          end
          return true
        end
      end, use_event.id)
      return yes
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = diezhang.name,
      cancelable = true,
      prompt = "#diezhangYang-invoke::"..data.to.id,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {data.to}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, diezhang.name, player, player)
    for _ = 1, 2 do
      if not player.dead and not data.to.dead then
        room:useVirtualCard("slash", nil, player, data.to, diezhang.name, true)
      end
    end
  end,
})

return diezhang
