local xili = fk.CreateSkill {
  name = "xili"
}

Fk:loadTranslationTable{
  ['xili'] = '系力',
  ['#xili-invoke'] = '系力：你可以弃置一张牌，令 %src 对 %dest 造成的伤害+1，你与 %src 各摸两张牌',
  [':xili'] = '每回合限一次，其他拥有〖系力〗的角色于其回合内对没有〖系力〗的角色造成伤害时，你可以弃置一张牌令此伤害+1，然后你与其各摸两张牌。',
  ['$xili1'] = '系力而为，助君得胜。',
  ['$xili2'] = '有我在，将军此战必能一举拿下！',
}

xili:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xili.name) and data.from and target ~= player and
      target:hasSkill(xili.name, true, true) and target.phase ~= Player.NotActive and
      not data.to:hasSkill(xili.name, true) and not player:isNude() and player:usedSkillTimes(xili.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = xili.name,
      cancelable = true,
      prompt = "#xili-invoke:"..data.from.id..":"..data.to.id,
    })
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self), xili.name, player, player)
    data.damage = data.damage + 1
    if not player.dead then
      player:drawCards(2, xili.name)
    end
    if not target.dead then
      target:drawCards(2, xili.name)
    end
  end,
})

return xili
