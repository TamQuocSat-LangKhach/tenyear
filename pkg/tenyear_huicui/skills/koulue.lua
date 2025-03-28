local koulue = fk.CreateSkill {
  name = "koulue",
}

Fk:loadTranslationTable{
  ["koulue"] = "寇略",
  [":koulue"] = "当你于出牌阶段内对其他角色造成伤害后，你可以展示其X张手牌（X为其已损失体力值），你获得其中的【杀】和伤害锦囊牌。"..
  "若展示牌中有红色牌：若你已受伤则减1点体力上限，未受伤则失去1点体力；然后你摸两张牌。",

  ["#koulue-invoke"] = "寇略：你可以展示 %dest 的手牌，获得其中的伤害牌",

  ["$koulue1"] = "兵强马壮，时出寇略。",
  ["$koulue2"] = "饥则寇略，饱则弃馀。",
}

koulue:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(koulue.name) and
      player.phase == Player.Play and data.to ~= player and
      not data.to.dead and not data.to:isKongcheng() and data.to:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = koulue.name,
      prompt = "#koulue-invoke::" .. data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      target = data.to,
      min = data.to:getLostHp(),
      max = data.to:getLostHp(),
      flag = "h",
      skill_name = koulue.name,
    })
    data.to:showCards(cards)
    if player.dead then return end
    local get = table.filter(cards, function(id)
      return Fk:getCardById(id).is_damage_card and table.contains(data.to:getCardIds("h"), id)
    end)
    if #get > 0 then
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonPrey, koulue.name, nil, true, player)
    end
    if not player.dead and table.find(cards, function(id)
      return Fk:getCardById(id).color == Card.Red
    end) then
      if player:isWounded() then
        room:changeMaxHp(player, -1)
      else
        room:loseHp(player, 1, koulue.name)
      end
      if not player.dead then
        player:drawCards(2, koulue.name)
      end
    end
  end,
})

return koulue
