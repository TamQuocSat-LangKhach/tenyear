local extension = Package:new("tenyear_other")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_other/skills")

Fk:loadTranslationTable{
  ["tenyear_other"] = "十周年-其他",
  ["tycl"] = "典",
  ["child"] = "儿童节",
}

General:new(extension, "longwang", "god", 3):addSkills { "ty__longgong", "ty__sitian" }
Fk:loadTranslationTable{
  ["longwang"] = "东海龙王",

  ["~longwang"] = "三年之期已到，哥们要回家啦…",
}

General:new(extension, "taoshen", "god", 4):addSkills { "ty__nutao" }
Fk:loadTranslationTable{
  ["taoshen"] = "涛神",
}

General:new(extension, "libai", "god", 3):addSkills { "jiuxian", "shixian" }
Fk:loadTranslationTable{
  ["libai"] = "李白",

  ["~libai"] = "谁识卧龙客，长吟愁鬓斑。",
}

General:new(extension, "khan", "god", 3):addSkills { "tongliao", "wudao" }
Fk:loadTranslationTable{
  ["khan"] = "小约翰可汗",
  ["cv:khan"] = "小约翰可汗",

  ["~khan"] = "留得青山在，老天爷饿不死瞎家雀。",
}

General:new(extension, "zhutiexiong", "god", 3):addSkills { "bianzhuang" }
Fk:loadTranslationTable{
  ["zhutiexiong"] = "朱铁雄",
  ["cv:zhutiexiong"] = "朱铁雄",

  ["~zhutiexiong"] = "那些看似很可笑的梦，是我们用尽全力守护的光……",
}

General:new(extension, "tycl__caocao", "wei", 4):addSkills { "tycl__jianxiong" }
Fk:loadTranslationTable{
  ["tycl__caocao"] = "经典曹操",
  ["#tycl__caocao"] = "魏武帝",
  ["illustrator:tycl__caocao"] = "Kayak",

  ["~tycl__caocao"] = "霸业未成未成啊！",
}

General:new(extension, "tycl__liubei", "shu", 4):addSkills { "tycl__rende" }
Fk:loadTranslationTable{
  ["tycl__liubei"] = "经典刘备",
  ["#tycl__liubei"] = "乱世的枭雄",
  ["illustrator:tycl__liubei"] = "Kayak",

  ["~tycl__liubei"] = "这就是桃园吗？",
}

General:new(extension, "tycl__sunquan", "wu", 4):addSkills { "tycl__zhiheng" }
Fk:loadTranslationTable{
  ["tycl__sunquan"] = "经典孙权",
  ["#tycl__sunquan"] = "年轻的贤君",
  ["illustrator:tycl__sunquan"] = "Kayak",

  ["~tycl__sunquan"] = "父亲大哥仲谋愧矣。",
}

General:new(extension, "sunwukong", "god", 3):addSkills { "jinjing", "ruyi", "cibeis" }
Fk:loadTranslationTable{
  ["sunwukong"] = "孙悟空",

  ["~sunwukong"] = "曾经有一整片蟠桃园在我面前，失去后才追悔莫及……",
}

local nezha = General:new(extension, "nezha", "god", 3)
nezha:addSkills { "santou", "faqi" }
nezha.fixMaxHp = 3
Fk:loadTranslationTable{
  ["nezha"] = "哪吒",

  ["~nezha"] = "莲藕花开，始知三清……",
}

General:new(extension, "tycl__sunce", "wu", 4):addSkills { "shuangbi" }
Fk:loadTranslationTable{
  ["tycl__sunce"] = "双璧孙策",
}

General:new(extension, "tycl__wuyi", "shu", 4):addSkills { "tycl__benxi" }
Fk:loadTranslationTable{
  ["tycl__wuyi"] = "名将吴懿",
  ["#tycl__wuyi"] = "五一名将",--称号出自天水濯名
  ["illustrator:tycl__wuyi"] = "biou09",
}

General:new(extension, "goddianwei", "god", 4):addSkills { "juanjia", "qiexie", "cuijue" }
Fk:loadTranslationTable{
  ["goddianwei"] = "神典韦",
  ["#goddianwei"] = "袒裼暴虎",
  ["illustrator:goddianwei"] = "君桓文化",

  ["~goddianwei"] = "战死沙场，快哉快哉！",
}

local c_sunquan = General:new(extension, "child__sunquan", "wu", 3)
c_sunquan:addSkills { "huiwan", "huanli" }
c_sunquan:addRelatedSkills { "zhijian", "guzheng", "ex__yingzi", "ex__fanjian", "ex__zhiheng" }
Fk:loadTranslationTable{
  ["child__sunquan"] = "小孙权",
  ["#child__sunquan"] = "牌堆的掌控者",--称号出自天水濯名
  ["illustrator:child__sunquan"] = "游漫美绘",

  ["~child__sunquan"] = "阿娘，大哥抢我糖人！",
}

General:new(extension, "quyuan", "qun", 3):addSkills { "qiusuo", "lisao" }
Fk:loadTranslationTable{
  ["quyuan"] = "屈原",
  ["cv:quyuan"] = "虞晓旭",

  ["~quyuan"] = "伏清白以死直兮，固前圣之所厚。",
}

General:new(extension, "wuming", "qun", 3):addSkills { "chushan" }
Fk:loadTranslationTable{
  ["wuming"] = "无名",
}

General:new(extension, "liuxiecaojie", "qun", 2):addSkills { "juanlv", "qixin" }
Fk:loadTranslationTable{
  ["liuxiecaojie"] = "刘协曹节",
}

General:new(extension, "xunyuxunyou", "wei", 3):addSkills { "zhinang", "gouzhu" }
Fk:loadTranslationTable{
  ["xunyuxunyou"] = "荀彧荀攸",
}

General:new(extension, "weiqing", "qun", 3):addSkills { "beijin" }
Fk:loadTranslationTable{
  ["weiqing"] = "卫青",
}

General:new(extension, "tycl__cenhun", "wu", 3):addSkills { "baoshi", "xinggong" }
Fk:loadTranslationTable{
  ["tycl__cenhun"] = "食岑昏",
}

General:new(extension, "tianjiq", "qun", 3):addSkills { "weijit", "saima" }
Fk:loadTranslationTable{
  ["tianjiq"] = "田忌",
}

return extension
