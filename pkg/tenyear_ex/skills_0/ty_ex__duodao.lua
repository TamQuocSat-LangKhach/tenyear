local ty_ex__duodao = fk.CreateSkill {
  name = "ty_ex__duodao"
}

Fk:loadTranslationTable{
  ['ty_ex__duodao'] = '夺刀',
  ['#ty_ex__duodao-invoke'] = '是否发动 夺刀，弃置一张牌，获得%dest装备区里的武器牌',
  [':ty_ex__duodao'] = '当你成为【杀】的目标后，若使用者装备区里有武器牌，你可以弃置一张牌，获得使用者装备区里的武器牌。',
  ['$ty_ex__duodao1'] = '宝刀配英雄，此刀志在必得！',
  ['$ty_ex__duodao2'] = '你根本不会用刀！'
}

ty_ex__duodao:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty_ex__duodao) and data.card.trueName == "slash" and not player:isNude() and data.from then
      local from = player.room:getPlayerById(data.from)
      return not from.dead and from:getEquipment(Card.SubtypeWeapon)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ty_ex__duodao.name,
      cancelable = true,
      prompt = "#ty_ex__duodao-invoke::" .. data.from
    })
    if #card > 0 then
      room:doIndicate(player.id, {data.from})
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self)
    room:throwCard(card, ty_ex__duodao.name, player, player)
    local from = room:getPlayerById(data.from)
    if from.dead or player.dead then return end
    local weapons = from:getEquipments(Card.SubtypeWeapon)
    if #weapons > 0 then
      room:moveCardTo(weapons, Player.Hand, player, fk.ReasonPrey, ty_ex__duodao.name, "", true, player.id)
    end
  end
})

return ty_ex__duodao
