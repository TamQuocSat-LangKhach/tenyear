local extension = Package:new("tenyear_star")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_star/skills")

Fk:loadTranslationTable{
  ["tenyear_star"] = "十周年-星河璀璨",
  ["tystar"] = "新服星",
}

--天枢：袁术 董卓 张昭 袁绍 张让
General:new(extension, "tystar__yuanshu", "qun", 4):addSkills { "canxi", "pizhi", "zhonggu" }
Fk:loadTranslationTable{
  ["tystar__yuanshu"] = "星袁术",
  ["#tystar__yuanshu"] = "狂貔猖貅",
  ["designer:tystar__yuanshu"] = "头发好借好还",
  ["illustrator:tystar__yuanshu"] = "黯荧岛工作室",

  ["~tystar__yuanshu"] = "英雄不死则已，死则举大名尔……",
}

General:new(extension, "tystar__dongzhuo", "qun", 5):addSkills { "weilin", "zhangrong", "haoshou" }
Fk:loadTranslationTable{
  ["tystar__dongzhuo"] = "星董卓",
  ["#tystar__dongzhuo"] = "千里草的魔阀",
  ["designer:tystar__dongzhuo"] = "对勾对勾w",
  ["illustrator:tystar__dongzhuo"] = "黯荧岛工作室",

  ["~tystar__dongzhuo"] = "美人迷人眼，溢权昏人智……",
}

General:new(extension, "tystar__zhangzhao", "wu", 3):addSkills { "zhongyanz", "jinglun" }
Fk:loadTranslationTable{
  ["tystar__zhangzhao"] = "星张昭",
  ["#tystar__zhangzhao"] = "忠謇方直",
  ["illustrator:tystar__zhangzhao"] = "君桓文化",

  ["~tystar__zhangzhao"] = "曹公虎豹也，不如以礼早降。",
}

General:new(extension, "tystar__yuanshao", "qun", 4):addSkills { "xiaoyan", "zongshiy", "jiaowang", "aoshi" }
Fk:loadTranslationTable{
  ["tystar__yuanshao"] = "星袁绍",
  ["#tystar__yuanshao"] = "熏灼群魔",
  ["designer:tystar__yuanshao"] = "步穗",
  ["illustrator:tystar__yuanshao"] = "鬼画府",

  ["~tystar__yuanshao"] = "骄兵必败，奈何不记前辙……",
}

General:new(extension, "tystar__zhangrang", "qun", 3):addSkills { "duhai", "lingse" }
Fk:loadTranslationTable{
  ["tystar__zhangrang"] = "星张让",
  ["#tystar__zhangrang"] = "斗筲穿窬",

  ["~tystar__zhangrang"] = "先皇啊，小陛下他拿咱不当人！",
}

--天璇：法正 荀彧
General:new(extension, "tystar__fazheng", "shu", 3):addSkills { "zhijif", "anji" }
Fk:loadTranslationTable{
  ["tystar__fazheng"] = "星法正",
  ["#tystar__fazheng"] = "定军佐功",
  ["illustrator:tystar__fazheng"] = "匠人绘",
  ["designer:tystar__fazheng"] = "懵萌猛梦",

  ["~tystar__fazheng"] = "我当为君之子房，奈何命寿将尽……",
}

local xunyu = General:new(extension, "tystar__xunyu", "wei", 3)
xunyu:addSkills { "anshu", "kuangzuo" }
xunyu:addRelatedSkills { "chengfeng", "tongyin" }
Fk:loadTranslationTable{
  ["tystar__xunyu"] = "星荀彧",
  ["#tystar__xunyu"] = "怀忠念治",
  ["designer:tystar__xunyu"] = "对勾对勾w",
  ["illustrator:tystar__xunyu"] = "黯荧岛",

  ["~tystar__xunyu"] = "臣固忠于国，非一家之臣。",
}

--玉衡：曹仁 张春华
General:new(extension, "tystar__caoren", "wei", 4):addSkills { "sujun", "lifengc" }
Fk:loadTranslationTable{
  ["tystar__caoren"] = "星曹仁",
  ["#tystar__caoren"] = "伏波四方",
  ["designer:tystar__caoren"] = "追风少年",
  ["illustrator:tystar__caoren"] = "君桓文化",

  ["~tystar__caoren"] = "濡须之败，此生之耻……",
}

General:new(extension, "tystar__zhangchunhua", "wei", 3, 3, General.Female):addSkills { "liangyan", "minghui" }
Fk:loadTranslationTable{
  ["tystar__zhangchunhua"] = "星张春华",
  ["#tystar__zhangchunhua"] = "皑雪皎月",
  ["designer:tystar__zhangchunhua"] = "黑寡妇",
  ["illustrator:tystar__zhangchunhua"] = "七兜豆",

  ["~tystar__zhangchunhua"] = "我何为也？竟称可憎之老物……",
}

--开阳：孙坚
General:new(extension, "tystar__sunjian", "qun", 4, 5):addSkills { "ruijun", "gangyi" }
Fk:loadTranslationTable{
  ["tystar__sunjian"] = "星孙坚",
  ["#tystar__sunjian"] = "破虏将军",
  ["illustrator:tystar__sunjian"] = "鬼画府",
  ["designer:tystar__sunjian"] = "韩旭",

  ["~tystar__sunjian"] = "身怀宝器，必受群狼觊觎……",
}

--瑶光：孙尚香 丁奉
General:new(extension, "tystar__sunshangxiang", "wu", 3, 3, General.Female):addSkills { "saying", "ty__jiaohao" }
Fk:loadTranslationTable{
  ["tystar__sunshangxiang"] = "星孙尚香",
  ["#tystar__sunshangxiang"] = "鸳袖衔剑珮",
  ["designer:tystar__sunshangxiang"] = "食饿不赦",
  ["illustrator:tystar__sunshangxiang"] = "匠人绘",

  ["~tystar__sunshangxiang"] = "秋风冷，江水寒……",
}

General:new(extension, "tystar__dingfeng", "wu", 4):addSkills { "dangchen", "jianyud" }
Fk:loadTranslationTable{
  ["tystar__dingfeng"] = "星丁奉",
  ["#tystar__dingfeng"] = "廓清阶陛",
  ["illustrator:tystar__dingfeng"] = "钟於",

  ["~tystar__dingfeng"] = "野豕入营，此凶徵也。",
}

return extension
