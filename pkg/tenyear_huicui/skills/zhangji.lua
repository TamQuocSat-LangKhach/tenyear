local zhangji = fk.CreateSkill {
  name = "ty__zhangjiq",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__zhangjiq"] = "长姬",
  [":ty__zhangjiq"] = "锁定技，一张牌指定包括你在内的多名角色为目标时，先结算对你产生的效果，然后你摸X张牌（X为剩余目标数）。",

  ["$ty__zhangjiq1"] = "功赏过惩，此魏武所教我者。",
  ["$ty__zhangjiq2"] = "长公主之言，谁敢不从？",
}

zhangji:addEffect(fk.BeforeCardUseEffect, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhangji.name) and #data.tos > 1 and
      table.contains(data.tos, player)
  end,
  on_use = function(self, event, target, player, data)
    local new_tos = {}
    for _, to in ipairs(data.tos) do
      if to == player then
        table.insert(new_tos, to)
      end
    end
    for _, to in ipairs(data.tos) do
      if to ~= player then
        table.insert(new_tos, to)
      end
    end
    data.tos = new_tos
    player:drawCards(#data.tos - 1, zhangji.name)
  end,
})

return zhangji
