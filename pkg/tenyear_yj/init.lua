local extension = Package:new("tenyear_yj")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_yj/skills")

Fk:loadTranslationTable{
  ["tenyear_yj"] = "十周年-一将成名",
}

--一将成名2022：陆凯 李婉 轲比能 诸葛尚 武安国 韩龙 苏飞 谯周
General:new(extension, "lukai", "wu", 4):addSkills { "bushil", "zhongzhuang" }
Fk:loadTranslationTable{
  ["lukai"] = "陆凯",
  ["#lukai"] = "青辞宰辅",
  ["illustrator:lukai"] = "游漫美绘",
  ["designer:lukai"] = "GT",

  ["~lukai"] = "不听忠言，国将亡矣……",
}

General:new(extension, "liwan", "wei", 3, 3, General.Female):addSkills { "liandui", "biejun" }
Fk:loadTranslationTable{
  ["liwan"] = "李婉",
  ["#liwan"] = "才媛淑美",
  ["illustrator:liwan"] = "荧光笔工作室",
  ["designer:lukai"] = "山巅隐士",

  ["~liwan"] = "生不能同寝，死亦难同穴……",
}

General:new(extension, "kebineng", "qun", 4):addSkills { "koujing" }
Fk:loadTranslationTable{
  ["kebineng"] = "轲比能",
  ["#kebineng"] = "瀚海鲸波",
  ["designer:kebineng"] = "zero",
  ["illustrator:kebineng"] = "君桓文化",

  ["~kebineng"] = "草原雄鹰，折翼于此……",
}

General:new(extension, "zhugeshang", "shu", 3):addSkills { "sangu", "yizu" }
Fk:loadTranslationTable{
  ["zhugeshang"] = "诸葛尚",
  ["#zhugeshang"] = "尚节殉义",
  ["designer:zhugeshang"] = "叫什么啊你妹",
  ["illustrator:zhugeshang"] = "君桓文化",

  ["~zhugeshang"] = "父子荷国重恩，当尽忠以报！",
}

General:new(extension, "wuanguo", "qun", 4):addSkills { "diezhang", "duanwan" }
Fk:loadTranslationTable{
  ["wuanguo"] = "武安国",
  ["#wuanguo"] = "虎口折腕",
  ["designer:wuanguo"] = "息吹123",
  ["illustrator:wuanguo"] = "目游",

  ["~wuanguo"] = "吕奉先，你给某家等着！",
}

General:new(extension, "hanlong", "wei", 4):addSkills { "duwang", "cibei" }
Fk:loadTranslationTable{
  ["hanlong"] = "韩龙",
  ["#hanlong"] = "冯河易水",
  ["designer:hanlong"] = "雾燎鸟",
  ["illustrator:hanlong"] = "游漫美绘",

  ["~hanlong"] = "杀轲比能者，韩龙也！",
}

General:new(extension, "ty__sufei", "wu", 4):addSkills { "shuojian" }
Fk:loadTranslationTable{
  ["ty__sufei"] = "苏飞",
  ["#ty__sufei"] = "义荐恩还",
  ["designer:ty__sufei"] = "文小远",
  ["illustrator:ty__sufei"] = "六道目",

  ["~ty__sufei"] = "兴霸何在？吾命休矣……",
}

General:new(extension, "ty__qiaozhou", "shu", 3):addSkills { "shiming", "jiangxi" }
Fk:loadTranslationTable{
  ["ty__qiaozhou"] = "谯周",
  ["#ty__qiaozhou"] = "谶星沉祚",
  ["designer:ty__qiaozhou"] = "夜者之歌",
  ["illustrator:ty__qiaozhou"] = "鬼画府",

  ["~ty__qiaozhou"] = "炎汉百年之业，吾一言毁之……",
}

--一将成名2023：孙礼 陈式 费曜 夏侯楙 徐琨 司马孚 令狐愚 宣公主 马钧 裴秀
General:new(extension, "sunli", "wei", 4):addSkills { "kangli" }
Fk:loadTranslationTable{
  ["sunli"] = "孙礼",
  ["#sunli"] = "百炼公才",
  ["designer:sunli"] = "老酒馆的猫",
  ["illustrator:sunli"] = "错落宇宙",

  ["~sunli"] = "国无矩不立，何谓之方圆……",
}

General:new(extension, "chenshi", "shu", 4):addSkills { "qingbei" }
Fk:loadTranslationTable{
  ["chenshi"] = "陈式",
  ["#chenshi"] = "裨将可期",
  ["designer:chenshi"] = "绯瞳",
  ["illustrator:chenshi"] = "游漫美绘",

  ["~chenshi"] = "丞相、丞相！是魏延指使我的！",
}

General:new(extension, "feiyao", "wei", 4):addSkills { "zhenfengf" }
Fk:loadTranslationTable{
  ["feiyao"] = "费曜",
  ["#feiyao"] = "后将军",
  ["designer:feiyao"] = "米陶诺斯",
  ["illustrator:feiyao"] = "青雨",

  ["~feiyao"] = "姜维！你果然是蜀军内应！",
}

General:new(extension, "xiahoumao", "wei", 4):addSkills { "tongwei", "cuguo" }
Fk:loadTranslationTable{
  ["xiahoumao"] = "夏侯楙",
  ["#xiahoumao"] = "束甲之鸟",
  ["designer:xiahoumao"] = "伯约的崛起",
  ["illustrator:xiahoumao"] = "君桓文化",

  ["~xiahoumao"] = "志大才疏，以致今日之祸……",
}

General:new(extension, "xukun", "wu", 4):addSkills { "fazhu" }
Fk:loadTranslationTable{
  ["xukun"] = "徐琨",
  ["#xukun"] = "平虏击逆",
  ["designer:xukun"] = "卤香蛋2",
  ["illustrator:xukun"] = "君桓文化",

  ["~xukun"] = "何处……射来的流矢……",
}

local simafu = General:new(extension, "ty__simafu", "wei", 3)
simafu.subkingdom = "jin"
simafu:addSkills { "beiyu", "duchi" }
Fk:loadTranslationTable{
  ["ty__simafu"] = "司马孚",
  ["#ty__simafu"] = "仁孝忠德",
  ["illustrator:ty__simafu"] = "君桓文化",
  ["designer:ty__simafu"] = "坑坑",

  ["~ty__simafu"] = "臣死之日，固大魏之纯臣也。",
}

General:new(extension, "linghuyu", "wei", 4):addSkills { "xuzhi" }
Fk:loadTranslationTable{
  ["linghuyu"] = "令狐愚",
  ["#linghuyu"] = "名愚性浚",
  ["designer:linghuyu"] = "浮兮璃璃",
  ["illustrator:linghuyu"] = "钟於",

  ["~linghuyu"] = "咳咳，我欲谋大事，奈何命不由己。",
}

local xuangongzhu = General:new(extension, "ty__xuangongzhu", "wei", 3, 3, General.Female)
xuangongzhu.subkingdom = "jin"
xuangongzhu:addSkills { "ty__qimei", "ty__zhuijix" }
Fk:loadTranslationTable{
  ["ty__xuangongzhu"] = "宣公主",
  ["#ty__xuangongzhu"] = "高陵翩蝶",
  ["illustrator:linghuyu"] = "黯荧岛",
  ["designer:ty__xuangongzhu"] = "谜城惊雨声",

  ["~ty__xuangongzhu"] = "夫君，妾身先行一步……",
}

General:new(extension, "ty__majun", "wei", 3):addSkills { "gongqiao", "jingyi" }
Fk:loadTranslationTable{
  ["ty__majun"] = "马钧",
  ["#ty__majun"] = "名巧天下",
  ["illustrator:ty__majun"] = "鬼画府",
  ["designer:ty__majun"] = "白日梦花",

  ["~ty__majun"] = "龙骨坍夜陌，水尽百戏枯……",
}

local weapon__gongqiao = fk.CreateCard{
  name = "&weapon__gongqiao",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
}
extension:loadCardSkels{weapon__gongqiao}
extension:addCardSpec("weapon__gongqiao")

local armor__gongqiao = fk.CreateCard{
  name = "&armor__gongqiao",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
}
extension:loadCardSkels{armor__gongqiao}
extension:addCardSpec("armor__gongqiao")

local offensive_horse__gongqiao = fk.CreateCard{
  name = "&offensive_horse__gongqiao",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
}
extension:loadCardSkels{offensive_horse__gongqiao}
extension:addCardSpec("offensive_horse__gongqiao")

local defensive_horse__gongqiao = fk.CreateCard{
  name = "&defensive_horse__gongqiao",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeDefensiveRide,
}
extension:loadCardSkels{defensive_horse__gongqiao}
extension:addCardSpec("defensive_horse__gongqiao")

local treasure__gongqiao = fk.CreateCard{
  name = "&treasure__gongqiao",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
}
extension:loadCardSkels{treasure__gongqiao}
extension:addCardSpec("treasure__gongqiao")
Fk:loadTranslationTable{
  ["weapon__gongqiao"] = "工巧",
  ["armor__gongqiao"] = "工巧",
  ["offensive_horse__gongqiao"] = "工巧",
  ["defensive_horse__gongqiao"] = "工巧",
  ["treasure__gongqiao"] = "工巧",
}

local peixiu = General:new(extension, "ty__peixiu", "qun", 3)
peixiu.subkingdom = "jin"
peixiu:addSkills { "zhitu", "fujue" }
Fk:loadTranslationTable{
  ["ty__peixiu"] = "裴秀",
  ["#ty__peixiu"] = "玄静守真",
  ["designer:ty__peixiu"] = "改名因为怕被喷",
  ["illustrator:ty__peixiu"] = "君桓文化",

  ["~ty__peixiu"] = "这酒，是冷的。",
}

return extension
