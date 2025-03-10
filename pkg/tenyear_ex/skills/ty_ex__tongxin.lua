local ty_ex__tongxin = fk.CreateSkill {
  name = "ty_ex__tongxin"
}

Fk:loadTranslationTable{
  ['ty_ex__tongxin'] = '同心',
  [':ty_ex__tongxin'] = '锁定技，你的攻击范围+2。',
}

ty_ex__tongxin:addEffect('atkrange', {
  correct_func = function(self, player, from, to)
    if player:hasSkill(ty_ex__tongxin.name) then
      return 2
    end
    return 0
  end,
})

return ty_ex__tongxin
