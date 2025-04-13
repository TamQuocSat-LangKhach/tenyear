local yanzhu_update = fk.CreateSkill {
  name = "ty_ex__yanzhu_update",
}

Fk:loadTranslationTable{
  ["ty_ex__yanzhu_update"] = "宴诛",
  [":ty_ex__yanzhu_update"] = "出牌阶段限一次，你可以选择一名其他角色，令其下次受到的伤害+1直到其下个回合开始。",
}

yanzhu_update:addEffect("visibility", {})

return yanzhu_update
