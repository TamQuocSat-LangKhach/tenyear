local fengshi = fk.CreateSkill {
  name = "ty__fengshi",
}

Fk:loadTranslationTable{
  ["ty__fengshi"] = "锋矢",
  [":ty__fengshi"] = "当你使用【杀】指定目标后，若你不在其攻击范围内，你可以弃置该角色装备区内的一张防具牌或防御坐骑牌。",

  ["#ty__fengshi-invoke"] = "锋矢：是否弃置 %dest 的防具牌或防御坐骑牌？",

  ["$ty__fengshi1"] = "大军压境，还不卸甲受降！",
  ["$ty__fengshi2"] = "放下兵器，饶你不死！"
}

fengshi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengshi.name) and data.card and data.card.trueName == "slash" and
      not data.to:inMyAttackRange(player) and not data.to.dead and
      (#data.to:getEquipments(Card.SubtypeArmor) > 0 or #data.to:getEquipments(Card.SubtypeDefensiveRide) > 0)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = fengshi.name,
      prompt = "#ty__fengshi-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(data.to:getEquipments(Card.SubtypeArmor))
    table.insertTableIfNeed(cards, table.simpleClone(data.to:getEquipments(Card.SubtypeDefensiveRide)))
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = { card_data = {{ data.to.general, cards }} },
      skill_name = fengshi.name,
    })
    room:throwCard(card, fengshi.name, data.to, player)
  end,
})

return fengshi
