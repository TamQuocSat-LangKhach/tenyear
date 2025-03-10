local yuwei = fk.CreateSkill {
  name = "yuwei$"
}

Fk:loadTranslationTable { }

yuwei:addEffect("compulsory", {
  can_trigger = function(self, event, target, player, data)
    -- 原触发技中的can_trigger逻辑放在这里
  end,
  on_trigger = function(self, event, target, player, data)
    -- 原触发技中的on_trigger逻辑放在这里

    -- 示例：读取和写入cost_data
    local a = event:getCostData(skill)
    event:setCostData(skill, xxx)
  end,
})

return yuwei
