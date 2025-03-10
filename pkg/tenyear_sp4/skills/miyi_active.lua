local miyi = fk.CreateSkill {
  name = "miyi"
}

Fk:loadTranslationTable{
  ['miyi_active'] = '蜜饴',
  ['miyi1'] = '各回复1点体力',
  ['miyi2'] = '各受到你的1点伤害',
}

miyi:addEffect('active', {
  card_num = 0,
  min_target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"miyi1", "miyi2"}}
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.TrueFunc,
})

return miyi
