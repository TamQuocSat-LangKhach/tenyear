local jiweic = fk.CreateSkill{
  name = "jiweic",
  attached_skill_name = "jiweic&",
}

Fk:loadTranslationTable{
  ["jiweic"] = "极威",
  [":jiweic"] = "其他魏势力角色的出牌阶段，其可以交给你一张手牌，然后你可以令其发动一次至多弃置3张牌的〖典论〗。",

  ["$jiweic1"] = "",
  ["$jiweic2"] = "",
}

jiweic:addEffect("visibility", {})

return jiweic
