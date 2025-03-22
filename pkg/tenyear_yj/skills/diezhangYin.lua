local diezhang = fk.CreateSkill {
  name = "diezhangYin",
}

Fk:loadTranslationTable{
  ["diezhangYin"] = "叠嶂",
  [":diezhangYin"] = "每回合限一次，当你使用牌抵消其他角色使用的牌后，你可以摸两张牌视为对其使用一张【杀】。",

  ["#diezhangYin-invoke"] = "叠嶂：你可以摸两张牌，视为对 %dest 使用【杀】",
}

diezhang:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(diezhang.name) and target ~= player and data.to == player and not target.dead and
      not player:isProhibited(target, Fk:cloneCard("slash")) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return end
      local yes = false
      player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.responseToEvent == data then
          if use.from == player then
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
    if room:askToSkillInvoke(player, {
      skill_name = diezhang.name,
      prompt = "#diezhangYin-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, diezhang.name)
    if not player.dead and not target.dead then
      room:useVirtualCard("slash", nil, player, target, diezhang.name, true)
    end
  end,
})

return diezhang
