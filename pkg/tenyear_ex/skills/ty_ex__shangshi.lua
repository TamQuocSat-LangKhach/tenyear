local ty_ex__shangshi = fk.CreateSkill {
  name = "ty_ex__shangshi"
}

Fk:loadTranslationTable{
  ['ty_ex__shangshi'] = '伤逝',
  ['#ty_ex__shangshi_discard'] = '伤逝',
  ['#shangshi-invoke'] = '伤逝：是否弃置一张手牌？',
  [':ty_ex__shangshi'] = '①当你受到伤害时，你可以弃置一张手牌；②每当你的手牌数小于你已损失的体力值时，可立即将手牌数补至等同于你已损失的体力值。',
}

ty_ex__shangshi:addEffect(fk.HpChanged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty_ex__shangshi) and player:getHandcardNum() < player:getLostHp() then
      return target == player
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getLostHp() - player:getHandcardNum(), ty_ex__shangshi.name)
  end,
})

ty_ex__shangshi:addEffect(fk.MaxHpChanged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty_ex__shangshi) and player:getHandcardNum() < player:getLostHp() then
      return target == player
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getLostHp() - player:getHandcardNum(), ty_ex__shangshi.name)
  end,
})

ty_ex__shangshi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty_ex__shangshi) and player:getHandcardNum() < player:getLostHp() then
      for _, move in ipairs(data) do
        return move.from == player.id
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getLostHp() - player:getHandcardNum(), ty_ex__shangshi.name)
  end,
})

ty_ex__shangshi:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("ty_ex__shangshi") and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = ty_ex__shangshi.name,
      prompt = "#shangshi-invoke"
    })
    if #card > 0 then
      event:setCostData(self, card[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self), ty_ex__shangshi.name, player, player)
  end,
})

return ty_ex__shangshi
