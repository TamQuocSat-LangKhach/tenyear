local ty__dingcuo = fk.CreateSkill {
  name = "ty__dingcuo"
}

Fk:loadTranslationTable{
  ['ty__dingcuo'] = '定措',
  [':ty__dingcuo'] = '每回合限一次，当你对其他角色造成伤害后，或当你受到其他角色造成的伤害后，你可摸两张牌，然后若这两张牌颜色不同，你须弃置一张手牌。',
  ['$ty__dingcuo1'] = '奋笔墨为锄，茁大汉以壮、慷国士以慨。',
  ['$ty__dingcuo2'] = '执金戈为尺，定国之方圆、立人之规矩。',
}

ty__dingcuo:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__dingcuo) and player:usedSkillTimes(ty__dingcuo.name, Player.HistoryTurn) == 0
      and not (data.to == player and data.from == player)
  end,
  on_use = function(self, event, target, player, data)
    local cards = player:drawCards(2, ty__dingcuo.name)
    if Fk:getCardById(cards[1]).color ~= Fk:getCardById(cards[2]).color and not player.dead then
      player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = ty__dingcuo.name,
        cancelable = false,
      })
    end
  end
})

ty__dingcuo:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__dingcuo) and player:usedSkillTimes(ty__dingcuo.name, Player.HistoryTurn) == 0
      and not (data.to == player and data.from == player)
  end,
  on_use = function(self, event, target, player, data)
    local cards = player:drawCards(2, ty__dingcuo.name)
    if Fk:getCardById(cards[1]).color ~= Fk:getCardById(cards[2]).color and not player.dead then
      player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = ty__dingcuo.name,
        cancelable = false,
      })
    end
  end
})

return ty__dingcuo
