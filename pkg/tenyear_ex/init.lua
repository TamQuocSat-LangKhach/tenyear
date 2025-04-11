local extension = Package:new("tenyear_ex")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_ex/skills")

Fk:loadTranslationTable{
  ["tenyear_ex"] = "十周年-界一将成名",
  ["ty_ex"] = "新服界",
}

General:new(extension, "ty_ex__caozhi", "wei", 3):addSkills { "luoying", "ty_ex__jiushi" }
Fk:loadTranslationTable{
  ["ty_ex__caozhi"] = "界曹植",
  ["#ty_ex__caozhi"] = "八斗之才",
  ["cv:ty_ex__caozhi"] = "秦且歌",
  ["illustrator:ty_ex__caozhi"] = "黯荧岛工作室",

  ["$luoying_ty_ex__caozhi1"] = "花落断情伤，心碎斩痴妄。",
  ["$luoying_ty_ex__caozhi2"] = "流水不言恨，落英难解愁。",
  ["~ty_ex__caozhi"] = "一生轻松待来生……",
}

General:new(extension, "ty_ex__zhangchunhua", "wei", 3, 3, General.Female):addSkills { "ty_ex__jueqing", "shangshi" }
Fk:loadTranslationTable{
  ["ty_ex__zhangchunhua"] = "界张春华",
  ["#ty_ex__zhangchunhua"] = "冷血皇后",
  ["illustrator:ty_ex__zhangchunhua"] = "磐浦",

  ["$jueqing_ty_ex__zhangchunhua1"] = "不知情之所起，亦不知情之所终。",
  ["$jueqing_ty_ex__zhangchunhua2"] = "唯有情字最伤人！",
  ["$shangshi_ty_ex__zhangchunhua1"] = "半生韶华随流水，思君不见撷落花。",
  ["$shangshi_ty_ex__zhangchunhua2"] = "西风知我意，送我三尺秋。",
  ["~ty_ex__zhangchunhua"] = "仲达负我！",
}

General:new(extension, "ty_ex__yujin", "wei", 4):addSkills { "ty_ex__zhenjun" }
Fk:loadTranslationTable{
  ["ty_ex__yujin"] = "界于禁",
  ["#ty_ex__yujin"] = "弗克其终",
  ["illustrator:ty_ex__yujin"] = "凝聚永恒",

  ["~ty_ex__yujin"] = "呃，晚节不保！",
}

General:new(extension, "ty_ex__fazheng", "shu", 3):addSkills { "ty_ex__enyuan", "ty_ex__xuanhuo" }
Fk:loadTranslationTable{
  ["ty_ex__fazheng"] = "界法正",
  ["#ty_ex__fazheng"] = "恩怨分明",
  ["illustrator:ty_ex__fazheng"] = "君桓文化",

  ["~ty_ex__fazheng"] = "恨未得见吾主，君临天下……",
}

General:new(extension, "ty_ex__masu", "shu", 3):addSkills { "ty_ex__sanyao", "ty_ex__zhiman" }
Fk:loadTranslationTable{
  ["ty_ex__masu"] = "界马谡",
  ["#ty_ex__masu"] = "街亭之殇",
  ["illustrator:ty_ex__masu"] = "匠人绘",

  ["~ty_ex__masu"] = "谡虽死无恨于黄壤也……",
}

local xushu = General:new(extension, "ty_ex__xushu", "shu", 4)
xushu:addSkills { "ty_ex__zhuhai", "ty_ex__qianxin" }
xushu:addRelatedSkill("ty_ex__jianyan")
Fk:loadTranslationTable{
  ["ty_ex__xushu"] = "界徐庶",
  ["#ty_ex__xushu"] = "折节学问",
  ["illustrator:ty_ex__xushu"] = "君桓文化",

  ["~ty_ex__xushu"] = "忠孝之德，庶两者皆空。",
}

General:new(extension, "ty_ex__lingtong", "wu", 4):addSkills { "ty_ex__xuanfeng", "ty_ex__yongjin" }
Fk:loadTranslationTable{
  ["ty_ex__lingtong"] = "界凌统",
  ["#ty_ex__lingtong"] = "豪情烈胆",
  ["cv:ty_ex__lingtong"] = "清水浊流",
  ["illustrator:ty_ex__lingtong"] = "聚一",

  ["~ty_ex__lingtong"] = "泉下弟兄，统来也！",
}

General:new(extension, "ty_ex__wuguotai", "wu", 3, 3, General.Female):addSkills { "ty_ex__ganlu", "ty_ex__buyi" }
Fk:loadTranslationTable{
  ["ty_ex__wuguotai"] = "界吴国太",
  ["#ty_ex__wuguotai"] = "武烈皇后",
  ["illustrator:ty_ex__wuguotai"] = "匠人绘",
  ["cv:ty_ex__wuguotai"] = "水原",

  ["~ty_ex__wuguotai"] = "爱女已去，老身何存？",
}

General:new(extension, "ty_ex__xusheng", "wu", 4):addSkills { "ty_ex__pojun" }
Fk:loadTranslationTable{
  ["ty_ex__xusheng"] = "界徐盛",
  ["#ty_ex__xusheng"] = "江东的铁壁",
  ["illustrator:ty_ex__xusheng"] = "黑羽",

  ["~ty_ex__xusheng"] = "文向已无憾矣！",
}

General:new(extension, "ty_ex__gaoshun", "qun", 4):addSkills { "ty_ex__xianzhen", "ty_ex__jinjiu" }
Fk:loadTranslationTable{
  ["ty_ex__gaoshun"] = "界高顺",
  ["#ty_ex__gaoshun"] = "攻无不克",
  ["illustrator:ty_ex__gaoshun"] = "兴游",

  ["~ty_ex__gaoshun"] = "力尽于布，与之偕死。",
}

General:new(extension, "ty_ex__chengong", "qun", 3):addSkills { "ty_ex__mingce", "zhichi" }
Fk:loadTranslationTable{
  ["ty_ex__chengong"] = "界陈宫",
  ["#ty_ex__chengong"] = "刚直壮烈",
  ["illustrator:ty_ex__chengong"] = "游歌",

  ["$zhichi_ty_ex__chengong1"] = "不若先行退避，再做打算。",
  ["$zhichi_ty_ex__chengong2"] = "敌势汹汹，不宜与其交锋。",
  ["~ty_ex__chengong"] = "一步迟，步步迟啊！",
}

return extension
