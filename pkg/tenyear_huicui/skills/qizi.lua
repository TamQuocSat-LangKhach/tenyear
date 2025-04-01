local qizi = fk.CreateSkill {
  name = "qizi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qizi"] = "弃子",
  [":qizi"] = "锁定技，其他角色处于濒死状态时，若你与其距离大于2，你不能对其使用【桃】。",
}

qizi:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return from:hasSkill(qizi.name) and card and card.name == "peach" and to.dying and from:distanceTo(to) > 2
  end,
})

return qizi
