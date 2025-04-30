local tiancheng = fk.CreateSkill{
  name = "tiancheng",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["tiancheng"] = "天承",
  [":tiancheng"] = "主公技，当你发动〖斩绊〗时，你可以选择任意名群势力角色不成为此次〖斩绊〗的目标。",

  ["#tiancheng-choose"] = "天承：你可以令任意名群势力角色不成为此次“斩绊”的目标",

  ["$tiancheng1"] = "大汉良臣，必得大汉天子护佑！",
  ["$tiancheng2"] = "忠臣不可罪，义士不可轻。",
}

tiancheng:addEffect("visibility", {
})

return tiancheng
