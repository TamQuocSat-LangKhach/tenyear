local cibeis = fk.CreateSkill {
  name = "cibeis"
}

Fk:loadTranslationTable{
  ['cibeis'] = '慈悲',
  ['#cibeis-invoke'] = '慈悲：你可以防止对 %src 造成伤害，摸五张牌',
  [':cibeis'] = '每回合每名角色限一次，当你对其他角色造成伤害时，你可以防止此伤害，摸五张牌。',
  ['$cibeis1'] = '生亦何欢，死亦何苦。',
  ['$cibeis2'] = '我欲成佛，天下无魔；我欲成魔，佛奈我何？',
}

cibeis:addEffect(fk.DamageCaused, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(cibeis.name) and target == player and player ~= data.to then
      return not table.contains(player:getTableMark("cibeis-turn"), data.to.id)
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = cibeis.name,
      prompt = "#cibeis-invoke:" .. data.to.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local mark = player:getTableMark("cibeis-turn")
    table.insert(mark, data.to.id)
    player.room:setPlayerMark(player, "cibeis-turn", mark)
    player:drawCards(5, cibeis.name)
    return true
  end,
})

return cibeis
