local ty_ex__weizhong = fk.CreateSkill {
  name = "ty_ex__weizhong"
}

Fk:loadTranslationTable{
  ['ty_ex__weizhong'] = '威重',
  [':ty_ex__weizhong'] = '锁定技，当你的体力上限变化时，你摸两张牌。',
  ['$ty_ex__weizhong'] = '待补充',
}

ty_ex__weizhong:addEffect(fk.MaxHpChanged, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    player:drawCards(2, ty_ex__weizhong.name)
  end,
})

return ty_ex__weizhong
