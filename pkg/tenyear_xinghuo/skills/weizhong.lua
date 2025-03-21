local weizhong = fk.CreateSkill {
  name = "ty_ex__weizhong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_ex__weizhong"] = "威重",
  [":ty_ex__weizhong"] = "锁定技，当你的体力上限变化后，你摸两张牌。",

  ["$ty_ex__weizhong"] = "食君之禄，当忠君之事！",
}

weizhong:addEffect(fk.MaxHpChanged, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    player:drawCards(2, weizhong.name)
  end,
})

return weizhong
