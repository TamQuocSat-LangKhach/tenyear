local yuwei = fk.CreateSkill {
  name = "yuwei",
  tags = { Skill.Lord, Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["yuwei"] = "余威",
  [":yuwei"] = "主公技，锁定技，其他群雄角色的回合内，〖诗怨〗改为“每回合每项限两次”。",
}

yuwei:addEffect("visibility", {})

return yuwei
