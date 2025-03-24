local geyuan = fk.CreateSkill {
  name = "geyuan_update",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["geyuan_update"] = "割圆",
  [":geyuan_update"] = "锁定技，有牌进入弃牌堆时，将满足圆环进度的点数记录在圆环内。当圆环完成后，你选择至多三名角色，按照选择顺序依次执行："..
  "1.摸三张牌；2.弃四张牌；3.将其手牌与牌堆底五张牌交换。结算完成后，重新开始圆环。",
}

geyuan:addEffect("visibility", {})

return geyuan
