local ty__fengshi = fk.CreateSkill {
  name = "ty__fengshi"
}

Fk:loadTranslationTable{
  ['ty__fengshi'] = '锋矢',
  ['#ty__fengshi-invoke'] = '锋矢：是否弃置 %dest 的防具牌或防御坐骑牌？',
  [':ty__fengshi'] = '当你使用【杀】指定目标后，若你不在其攻击范围内，你可以弃置该角色装备区内的一张防具牌或防御坐骑牌。',
  ['$ty__fengshi1'] = '大军压境，还不卸甲受降！',
  ['$ty__fengshi2'] = '放下兵器，饶你不死！'
}

ty__fengshi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty__fengshi.name) and data.card and data.card.trueName == "slash" then
      local to = player.room:getPlayerById(data.to)
      return not to:inMyAttackRange(player) and not to.dead and
        (#to:getEquipments(Card.SubtypeArmor) > 0 or #to:getEquipments(Card.SubtypeDefensiveRide) > 0)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local cards = table.simpleClone(to:getEquipments(Card.SubtypeArmor))
    table.insertTableIfNeed(cards, table.simpleClone(to:getEquipments(Card.SubtypeDefensiveRide)))
    local card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      choices = {"OK"},
      skill_name = ty__fengshi.name,
      prompt = "#ty__fengshi-invoke::" .. data.to,
      cancelable_choices = {"Cancel"}
    })
    if #card[2] > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    room:throwCard(cost_data, ty__fengshi.name, room:getPlayerById(data.to), player)
  end,
})

return ty__fengshi
