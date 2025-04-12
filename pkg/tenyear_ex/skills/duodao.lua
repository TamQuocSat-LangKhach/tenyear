local duodao = fk.CreateSkill {
  name = "ty_ex__duodao",
}

Fk:loadTranslationTable{
  ["ty_ex__duodao"] = "夺刀",
  [":ty_ex__duodao"] = "当你成为【杀】的目标后，你可以弃置一张牌，获得使用者装备区里的武器牌。",

  ["#ty_ex__duodao-invoke"] = "夺刀：你可以弃置一张牌，获得 %dest 的武器",

  ["$ty_ex__duodao1"] = "宝刀配英雄，此刀志在必得！",
  ["$ty_ex__duodao2"] = "你根本不会用刀！"
}

duodao:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duodao.name) and
      data.card.trueName == "slash" and not player:isNude() and
      #data.from:getEquipments(Card.SubtypeWeapon) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = duodao.name,
      cancelable = true,
      prompt = "#ty_ex__duodao-invoke::"..data.from.id,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {data.from}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, duodao.name, player, player)
    if not data.from or data.from.dead or data.from.dead then return end
    if #data.from:getEquipments(Card.SubtypeWeapon) then
      room:obtainCard(player, data.from:getEquipments(Card.SubtypeWeapon), true, fk.ReasonPrey, player, duodao.name)
    end
  end
})

return duodao
