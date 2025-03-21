local extension = Package:new("tenyear_wei")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_wei/skills")

Fk:loadTranslationTable{
  ["tenyear_wei"] = "十周年-威",
  ["ty_wei"] = "威",
}

--威震天下
General:new(extension, "ty_wei__zhangliao", "qun", 4):addSkills { "yuxi", "porong" }
Fk:loadTranslationTable{
  ["ty_wei__zhangliao"] = "威张辽",
  ["#ty_wei__zhangliao"] = "威锐镇西风",
  ["illustrator:ty_wei__zhangliao"] = "鬼画府",
  ["designer:ty_wei__zhangliao"] = "银蛋",

  ["~ty_wei__zhangliao"] = "血染战袍，虽死犹荣，此心无憾！",
}

General:new(extension, "ty_wei__lvbu", "qun", 5):addSkills { "xiaowul", "baguan" }
Fk:loadTranslationTable{
  ["ty_wei__lvbu"] = "威吕布",
  ["#ty_wei__lvbu"] = "虓虎叱北地",
  ["illustrator:ty_wei__lvbu"] = "第七个桔子",

  ["~ty_wei__lvbu"] = "虓虎失落尽，日暮无归途。",
}

--君威盖世
General:new(extension, "ty_wei__sunquan", "wu", 4):addSkills { "woheng", "yuhui" }
Fk:loadTranslationTable{
  ["ty_wei__sunquan"] = "威孙权",
  ["#ty_wei__sunquan"] = "坐断东南",
  ["illustrator:ty_wei__sunquan"] = "鬼画府",

  ["~ty_wei__sunquan"] = "自古许多忧，英雄老来愁……",
}

return extension
