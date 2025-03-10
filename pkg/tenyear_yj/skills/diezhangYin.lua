local diezhangYin = fk.CreateSkill {
  name = "diezhangYin"
}

Fk:loadTranslationTable{
  ['diezhangYin'] = '叠嶂',
  ['#diezhangYin-invoke'] = '叠嶂：你可以摸两张牌，视为对 %dest 使用【杀】',
  [':diezhangYin'] = '每回合限一次，当你使用牌抵消其他角色使用的牌后，你可以摸两张牌视为对其使用一张【杀】。',
}

diezhangYin:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(diezhangYin.name) and data.responseToEvent then
      local from = player.room:getPlayerById(data.responseToEvent.from)
      return from ~= player and not from.dead and not player:isProhibited(from, Fk:cloneCard("slash"))
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = diezhangYin.name,
      prompt = "#diezhangYin-invoke::" .. data.responseToEvent.from
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.responseToEvent.from)
    player:drawCards(2, diezhangYin.name)
    if not player.dead and not to.dead then
      room:useVirtualCard("slash", nil, player, to, diezhangYin.name, true)
    end
  end,
})

return diezhangYin
