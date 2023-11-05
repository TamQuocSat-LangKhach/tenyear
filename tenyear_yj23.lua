local extension = Package("tenyear_yj23")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_yj23"] = "十周年-一将2023",
}

--陈式
Fk:loadTranslationTable{
  ["chenshi"] = "陈式",
  ["qingbei"] = "擎北",
  [":qingbei"] = "每轮开始时，你可以选择任意种花色令你本轮无法使用，然后本轮你使用一张手牌后，摸本轮〖擎北〗选择过的花色数的牌。",
}

return extension
