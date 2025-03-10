local diezhangYang = fk.CreateSkill {
  name = "diezhangYang"
}

Fk:loadTranslationTable{
  ['diezhangYang'] = '叠嶂',
  ['#diezhangYang-invoke'] = '叠嶂：你可以弃置一张牌，视为对 %dest 使用两张【杀】',
  [':diezhangYang'] = '每回合限一次，当你使用牌被其他角色抵消后，你可以弃置一张牌视为对其使用两张【杀】。',
}

diezhangYang:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(diezhangYang) and data.responseToEvent and data.responseToEvent.from == player.id and not player:isNude() and
      target ~= player and not target.dead and not player:isProhibited(target, Fk:cloneCard("slash"))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = diezhangYang.name,
      cancelable = true,
      prompt = "#diezhangYang-invoke::" .. target.id
    })
    if #card > 0 then
      event:setCostData(skill, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(skill), diezhangYang.name, player, player)
    for i = 1, 2 do
      if not player.dead and not target.dead then
        room:useVirtualCard("slash", nil, player, target, diezhangYang.name, true)
      end
    end
  end,
})

return diezhangYang
