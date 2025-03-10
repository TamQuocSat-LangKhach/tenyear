local ty__yanhuo = fk.CreateSkill {
  name = "ty__yanhuo"
}

Fk:loadTranslationTable{
  ['ty__yanhuo'] = '延祸',
  ['#yanhuo-invoke'] = '延祸：你可以令本局接下来所有【杀】的伤害基数值+1！',
  [':ty__yanhuo'] = '当你死亡时，你可以令本局接下来所有【杀】的伤害基数值+1。',
  ['$ty__yanhuo1'] = '你们，都要为我殉葬！',
  ['$ty__yanhuo2'] = '杀了我，你们也别想活！',
}

ty__yanhuo:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__yanhuo.name, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty__yanhuo.name,
      prompt = "#yanhuo-invoke"
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:setTag("yanhuo", true)
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player.room:getTag("yanhuo") and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

return ty__yanhuo
