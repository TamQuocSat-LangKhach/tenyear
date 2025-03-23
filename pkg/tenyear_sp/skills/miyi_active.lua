local miyi = fk.CreateSkill {
  name = "miyi_active"
}

Fk:loadTranslationTable{
  ["miyi_active"] = "蜜饴",
}

miyi:addEffect("active", {
  card_num = 0,
  min_target_num = 1,
  interaction =  UI.ComboBox {choices = {"miyi1", "miyi2"}},
  card_filter = Util.FalseFunc,
  target_filter = Util.TrueFunc,
})

return miyi
