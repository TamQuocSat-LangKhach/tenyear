local xianwang = fk.CreateSkill {
  name = "xianwang"
}

Fk:loadTranslationTable{
  ['xianwang'] = '贤望',
  [':xianwang'] = '锁定技，若你有废除的装备栏，其他角色计算与你的距离+1，你计算与其他角色的距离-1；若你有至少三个废除的装备栏，以上数字改为2。',
  ['$xianwang1'] = '浩气长存，以正压邪。',
  ['$xianwang2'] = '名彰千里，盗无敢侵。',
}

xianwang:addEffect('distance', {
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if from:hasSkill(xianwang.name) then
      local n = #table.filter(from.sealedSlots, function(slot) return slot ~= "JudgeSlot" end)
      if n > 3 then
        return -2
      elseif n > 0 then
        return -1
      end
    end
    if to:hasSkill(xianwang.name) then
      local n = #table.filter(to.sealedSlots, function(slot) return slot ~= "JudgeSlot" end)
      if n > 3 then
        return 2
      elseif n > 0 then
        return 1
      end
    end
    return 0
  end,
})

return xianwang
