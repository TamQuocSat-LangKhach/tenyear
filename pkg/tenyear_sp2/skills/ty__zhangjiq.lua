local ty__zhangjiq = fk.CreateSkill {
  name = "ty__zhangjiq"
}

Fk:loadTranslationTable{
  ['ty__zhangjiq'] = '长姬',
  [':ty__zhangjiq'] = '锁定技，一张牌指定包括你在内的多名角色为目标时，先结算对你产生的效果，然后你摸X张牌（X为剩余目标数）。',
  ['$ty__zhangjiq1'] = '功赏过惩，此魏武所教我者。',
  ['$ty__zhangjiq2'] = '长公主之言，谁敢不从？',
}

ty__zhangjiq:addEffect(fk.BeforeCardUseEffect, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ty__zhangjiq.name) and #TargetGroup:getRealTargets(data.tos) > 1 and
      table.contains(TargetGroup:getRealTargets(data.tos), player.id)
  end,
  on_use = function(self, event, target, player, data)
    local new_tos = {}
    for _, info in ipairs(data.tos) do
      if info[1] == player.id then
        table.insert(new_tos, info)
      end
    end
    for _, info in ipairs(data.tos) do
      if info[1] ~= player.id then
        table.insert(new_tos, info)
      end
    end
    data.tos = new_tos
    player:drawCards(#TargetGroup:getRealTargets(data.tos) - 1, { skill_name = ty__zhangjiq.name })
  end,
})

return ty__zhangjiq
