local ty__benyu = fk.CreateSkill {
  name = "ty__benyu"
}

Fk:loadTranslationTable{
  ['ty__benyu'] = '贲育',
  ['ty__benyu_active'] = '贲育',
  ['ty__benyu_damage'] = '弃牌并造成伤害',
  [':ty__benyu'] = '当你受到伤害后，你可以选择一项：1.将手牌摸至X张（最多摸至5张）；2.弃置至少X+1张牌，然后对伤害来源造成1点伤害（X为伤害来源的手牌数）。',
  ['$ty__benyu1'] = '助曹公者昌，逆曹公者亡！',
  ['$ty__benyu2'] = '愚民不可共济大事，必当与智者为伍。',
}

ty__benyu:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__benyu) and data.from and not data.from.dead
      and (player:getHandcardNum() < math.min(data.from:getHandcardNum(), 5) or #player:getCardIds("he") > data.from:getHandcardNum())
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty__benyu_active",
      cancelable = true,
      extra_data = {ty__benyu_data = {data.from.id, data.from:getHandcardNum()}},
    })
    if success and dat then
      room:doIndicate(player.id, {data.from.id})
      event:setCostData(self, dat)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost_data = event:getCostData(self)
    if cost_data.interaction == "ty__benyu_damage" then
      player.room:throwCard(cost_data.cards, ty__benyu.name, player, player)
      player.room:damage{
        from = player,
        to = data.from,
        damage = 1,
        skillName = ty__benyu.name,
      }
    else
      player:drawCards(math.min(5, data.from:getHandcardNum()) - player:getHandcardNum())
    end
  end,
})

return ty__benyu
