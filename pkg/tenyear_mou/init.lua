local extension = Package:new("tenyear_mou")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_mou/skills")

Fk:loadTranslationTable{
  ["tenyear_mou"] = "十周年-谋",
  ["tymou"] = "新服谋",
  ["tymou2"] = "新服谋",
}

--谋定天下：周瑜 鲁肃 司马懿 贾诩 郭嘉
General:new(extension, "tymou__zhouyu", "wu", 4):addSkills { "ronghuo", "yingmou" }
local zhouyu2 = General:new(extension, "tymou2__zhouyu", "wu", 4)
zhouyu2:addSkills { "ronghuo", "yingmou" }
zhouyu2.hidden = true
Fk:loadTranslationTable{
  ["tymou__zhouyu"] = "谋周瑜",
  ["#tymou__zhouyu"] = "炽谋英隽",
  ["illustrator:tymou__zhouyu"] = "鬼画府",

  ["~tymou__zhouyu"] = "人生之艰难，犹如不息之长河……",

  ["tymou2__zhouyu"] = "谋周瑜",
  ["#tymou2__zhouyu"] = "炽谋英隽",
  ["illustrator:tymou2__zhouyu"] = "鬼画府",

  ["$ronghuo_tymou2__zhouyu1"] = "江东多锦绣，离火起曹贼毕，九州同忾。",
  ["$ronghuo_tymou2__zhouyu2"] = "星火乘风，风助火势，其必成燎原之姿。",
  ["$yingmou_tymou2__zhouyu1"] = "既遇知己之明主，当福祸共之，荣辱共之。",
  ["$yingmou_tymou2__zhouyu2"] = "将者，贵在知敌虚实，而后避实而击虚。",
  ["~tymou2__zhouyu"] = "大业未成，奈何身赴黄泉……",
}

General:new(extension, "tymou__lusu", "wu", 3):addSkills { "mingshil", "mengmou" }
local lusu2 = General:new(extension, "tymou2__lusu", "wu", 3)
lusu2:addSkills { "mingshil", "mengmou" }
lusu2.hidden = true
Fk:loadTranslationTable{
  ["tymou__lusu"] = "谋鲁肃",
  ["#tymou__lusu"] = "鸿谋翼远",
  ["illustrator:tymou__lusu"] = "鬼画府",

  ["~tymou__lusu"] = "虎可为之用，亦可为之伤……",

  ["tymou2__lusu"] = "谋鲁肃",
  ["#tymou2__lusu"] = "鸿谋翼远",
  ["illustrator:tymou2__lusu"] = "鬼画府",

  ["$mingshil_tymou2__lusu1"] = "今天下春秋已定，君不见南北沟壑乎？",
  ["$mingshil_tymou2__lusu2"] = "善谋者借势而为，其化万物为己用。",
  ["$mengmou_tymou2__lusu1"] = "合左抑右，定两家之盟。",
  ["$mengmou_tymou2__lusu2"] = "求同存异，邀英雄问鼎。",
  ["~tymou2__lusu"] = "青龙已巢，以何驱之……",
}

General:new(extension, "tymou__simayi", "wei", 3):addSkills { "pingliao", "quanmou" }
local simayi2 = General:new(extension, "tymou2__simayi", "wei", 3)
simayi2:addSkills { "pingliao", "quanmou" }
simayi2.hidden = true
Fk:loadTranslationTable{
  ["tymou__simayi"] = "谋司马懿",
  ["#tymou__simayi"] = "韬谋韫势",
  ["designer:tymou__simayi"] = "星移",
  ["illustrator:tymou__simayi"] = "米糊PU",

  ["~tymou__simayi"] = "以权谋而立者，必失大义于千秋……",

  ["tymou2__simayi"] = "谋司马懿",
  ["#tymou2__simayi"] = "韬谋韫势",
  ["illustrator:tymou2__simayi"] = "鬼画府",
  ["designer:tymou2__simayi"] = "星移",

  ["$pingliao_tymou2__simayi1"] = "率土之滨皆为王臣，辽土亦居普天之下。",
  ["$pingliao_tymou2__simayi2"] = "青云远上，寒锋试刃，北雁当寄红翎。",
  ["$quanmou_tymou2__simayi1"] = "鸿门之宴虽歇，会稽之胆尚悬，孤岂姬、项之辈？",
  ["$quanmou_tymou2__simayi2"] = "昔藏青锋于沧海，今潮落，可现兵！",
  ["~tymou2__simayi"] = "人立中流，非已力可向，实大势所迫……",
}

local jiaxu = General:new(extension, "tymou__jiaxu", "qun", 3)
jiaxu:addSkills { "sushen", "fumouj" }
jiaxu:addRelatedSkill("rushi")
local jiaxu2 = General:new(extension, "tymou2__jiaxu", "qun", 3)
jiaxu2:addSkills { "sushen", "fumouj" }
jiaxu2:addRelatedSkill("rushi")
jiaxu2.hidden = true
Fk:loadTranslationTable{
  ["tymou__jiaxu"] = "谋贾诩",
  ["#tymou__jiaxu"] = "晦谋独善",
  ["designer:tymou__jiaxu"] = "星移",
  ["illustrator:tymou__jiaxu"] = "鬼画府",

  ["~tymou__jiaxu"] = "辛者抱薪，妄燃烽火以戏诸侯……",

  ["tymou2__jiaxu"] = "谋贾诩",
  ["#tymou2__jiaxu"] = "晦谋独善",
  ["illustrator:tymou2__jiaxu"] = "鬼画府",
  ["designer:tymou2__jiaxu"] = "星移",

  ["$sushen_tymou2__jiaxu1"] = "我有三窟之筹谋，不蹈背水之维谷。",
  ["$sushen_tymou2__jiaxu2"] = "已积千里跬步，欲履万里河山。",
  ["$rushi_tymou2__jiaxu1"] = "曾寄青鸟凌云志，归来城头看王旗。",
  ["$rushi_tymou2__jiaxu2"] = "烽火照长安，淯水洗枯骨，今日对弈何人？",
  ["$fumouj_tymou2__jiaxu1"] = "不周之柱已折，这世间，当起一阵风、落一场雨！",
  ["$fumouj_tymou2__jiaxu2"] = "善谋者，不与善战者争功。",
  ["~tymou2__jiaxu"] = "未见青山草木，枯骨徒付浊流……",
}

local guojia = General:new(extension, "tymou__guojia", "wei", 3)
guojia:addSkills { "xianmou", "tymou__lunshi" }
guojia:addRelatedSkill("ex__yiji")
local guojia2 = General:new(extension, "tymou2__guojia", "wei", 3)
guojia2:addSkills { "xianmou", "tymou__lunshi" }
guojia2:addRelatedSkill("ex__yiji")
guojia2.hidden = true
Fk:loadTranslationTable{
  ["tymou__guojia"] = "谋郭嘉",
  ["#tymou__guojia"] = "翼谋奇佐",
  ["designer:tymou__guojia"] = "懵萌猛梦",
  ["illustrator:tymou__guojia"] = "鬼画府",

  ["$ex__yiji_tymou__guojia1"] = "算无遗策，方能决胜于千里。",
  ["$ex__yiji_tymou__guojia2"] = "吾身虽殒，然智计长存。",
  ["~tymou__guojia"] = "生如夏花，死亦何憾？",

  ["tymou2__guojia"] = "谋郭嘉",
  ["#tymou2__guojia"] = "翼谋奇佐",
  ["illustrator:tymou2__guojia"] = "鬼画府",
  ["designer:tymou2__guojia"] = "懵萌猛梦",

  ["$xianmou_tymou2__guojia1"] = "嘉不受此劫，安能以凡人之躯窥得天机！",
  ["$xianmou_tymou2__guojia2"] = "九州为觞，风雨为酿，谁与我共饮此杯？",
  ["$tymou__lunshi_tymou2__guojia1"] = "公有此十胜，败绍非难事尔。",
  ["$tymou__lunshi_tymou2__guojia2"] = "嘉窃料之，绍有十败，公有十胜。",
  ["$ex__yiji_tymou2__guojia1"] = "今生不借此身度，更向何生度此身？",
  ["$ex__yiji_tymou2__guojia2"] = "胸怀丹心一颗，欲照山河万朵。",
  ["~tymou2__guojia"] = "江湖路远，诸君，某先行一步。",
}

General:new(extension, "tymou__xunyu", "wei", 3):addSkills { "bizuo", "shimou" }
local xunyu2 = General:new(extension, "tymou2__xunyu", "wei", 3)
xunyu2:addSkills { "bizuo", "shimou" }
xunyu2.hidden = true
Fk:loadTranslationTable{
  ["tymou__xunyu"] = "谋荀彧",
  ["#tymou__xunyu"] = "贞谋弼汉",
  ["illustrator:tymou__xunyu"] = "鬼画府",

  ["~tymou__xunyu"] = "诸君见我冢，亦如见青山。",

  ["tymou2__xunyu"] = "谋荀彧",
  ["#tymou2__xunyu"] = "贞谋弼汉",
  ["illustrator:tymou2__xunyu"] = "鬼画府",

  ["$bizuo_tymou2__xunyu1"] = "而今江山未靖，劝君择日称公。",
  ["$bizuo_tymou2__xunyu2"] = "请君三尺剑，诛罢宵小，再复江山！",
  ["$shimou_tymou2__xunyu1"] = "明公揽青兖，征睢洛，胜券已然在握。",
  ["$shimou_tymou2__xunyu2"] = "为大汉抱薪者，不可使其冻毙于风雨。",
  ["~tymou2__xunyu"] = "知我罪我，其惟春秋。",
}

--冢虎狼顾：蒋济 王凌 司马师 曹爽
General:new(extension, "tymou__jiangji", "wei", 3):addSkills { "shiju", "yingshij" }
Fk:loadTranslationTable{
  ["tymou__jiangji"] = "谋蒋济",
  ["#tymou__jiangji"] = "策论万机",
  ["illustrator:tymou__jiangji"] = "错落宇宙",
  ["designer:tymou__jiangji"] = "黑寡妇",

  ["~tymou__jiangji"] = "大醉解忧，然忧无解，唯忘耳……",
}

local wangling = General:new(extension, "tymou__wangling", "wei", 4)
wangling:addSkills { "jichouw", "ty__mouli" }
wangling:addRelatedSkill("ty__zifu")
Fk:loadTranslationTable{
  ["tymou__wangling"] = "谋王凌",
  ["#tymou__wangling"] = "风节格尚",
  ["illustrator:tymou__wangling"] = "鬼画府",
  ["designer:tymou__wangling"] = "韩旭",

  ["~tymou__wangling"] = "曹魏之盛，再难复梦……",
}

General:new(extension, "tymou__simashi", "wei", 3):addSkills { "sanshi", "zhenrao", "chenlue" }
Fk:loadTranslationTable{
  ["tymou__simashi"] = "谋司马师",
  ["#tymou__simashi"] = "唯几成务",
  ["illustrator:tymou__simashi"] = "鬼画府",
  ["designer:tymou__simashi"] = "韩旭",

  ["~tymou__simashi"] = "东兴之败，此我过也，诸将何罪……",
}

local caoshuang = General:new(extension, "tymou__caoshuang", "wei", 4)
caoshuang:addSkills { "jianzhuan", "fanshi" }
caoshuang:addRelatedSkill("fudou")
Fk:loadTranslationTable{
  ["tymou__caoshuang"] = "谋曹爽",
  ["#tymou__caoshuang"] = "托孤傲臣",
  ["illustrator:tymou__caoshuang"] = "鬼画府",
  ["designer:tymou__caoshuang"] = "韩旭",

  ["~tymou__caoshuang"] = "我度太傅之意，不欲伤我兄弟耳……",
}

--子敬邀刀：诸葛瑾 关平
local zhugejin = General:new(extension, "tymou__zhugejin", "wu", 3)
zhugejin:addSkills { "taozhou", "houde" }
zhugejin:addRelatedSkill("zijin")
Fk:loadTranslationTable{
  ["tymou__zhugejin"] = "谋诸葛瑾",
  ["#tymou__zhugejin"] = "清雅德纯",
  ["illustrator:tymou__zhugejin"] = "君桓文化",
  ["designer:tymou__zhugejin"] = "银蛋",

  ["~tymou__zhugejin"] = "吾数梦，琅琊旧园……",
}

General:new(extension, "tymou__guanping", "shu", 4):addSkills { "wuwei" }
Fk:loadTranslationTable{
  ["tymou__guanping"] = "谋关平",
  ["#tymou__guanping"] = "百战烈烈",
  ["designer:tymou__guanping"] = "银蛋",
  ["cv:tymou__guanping"] = "清水浊流",
  ["illustrator:tymou__guanping"] = "黯荧岛",

  ["~tymou__guanping"] = "生未屈刀兵，死罢战黄泉……",
}

--毒士鸩计：张绣 典韦 胡车儿
General:new(extension, "tymou__zhangxiu", "qun", 4):addSkills { "fuxi", "haoyi" }
Fk:loadTranslationTable{
  ["tymou__zhangxiu"] = "谋张绣",
  ["#tymou__zhangxiu"] = "凌枪破宛",
  ["illustrator:tymou__zhangxiu"] = "君桓文化",
  ["designer:tymou__zhangxiu"] = "银蛋",

  ["~tymou__zhangxiu"] = "曹贼……欺我太甚！",
}

General:new(extension, "tymou__dianwei", "wei", 4, 5):addSkills { "kuangzhan", "kangyong" }
Fk:loadTranslationTable{
  ["tymou__dianwei"] = "谋典韦",
  ["#tymou__dianwei"] = "狂战怒莽",
  ["illustrator:tymou__dianwei"] = "黯荧岛",
  ["designer:tymou__dianwei"] = "银蛋",

  ["~tymou__dianwei"] = "主公无恙，韦虽死犹生……",
}

General:new(extension, "tymou__hucheer", "qun", 4):addSkills { "kongwu" }
Fk:loadTranslationTable{
  ["tymou__hucheer"] = "谋胡车儿",
  ["#tymou__hucheer"] = "有力逮戟",
  ["illustrator:tymou__hucheer"] = "钟於",

  ["~tymou__hucheer"] = "典，典将军，您还没睡呀？",
}

General:new(extension, "tymou__caoang", "wei", 4):addSkills { "fengmin", "zhiwang" }
Fk:loadTranslationTable{
  ["tymou__caoang"] = "谋曹昂",
  ["#tymou__caoang"] = "两全忠孝",
  --["illustrator:tymou__caoang"] = "",

  --["~tymou__caoang"] = "",
}

--奇佐论胜：沮授 陈琳
General:new(extension, "tymou__jvshou", "qun", 3):addSkills { "zuojun", "muwang" }
Fk:loadTranslationTable{
  ["tymou__jvshou"] = "谋沮授",
  ["#tymou__jvshou"] = "忠不逢时",
  ["illustrator:tymou__jvshou"] = "鬼画府",
  ["designer:tymou__jvshou"] = "步穗",

  ["~tymou__jvshou"] = "身虽死，忠魂不灭。",
}

General:new(extension, "tymou__chenlin", "qun", 3):addSkills { "yaozuo", "zhuanwen" }
Fk:loadTranslationTable{
  ["tymou__chenlin"] = "谋陈琳",
  ["#tymou__chenlin"] = "文翻云海",
  ["illustrator:tymou__chenlin"] = "鬼画府",
  ["designer:tymou__chenlin"] = "银蛋",

  ["~tymou__chenlin"] = "矢在弦上，不得不发，请曹公恕罪。",
}

--王佐倡义：董承 曹洪 刘协
General:new(extension, "tymou__liuxie", "qun", 3):addSkills { "zhanban", "chensheng", "tiancheng" }
Fk:loadTranslationTable{
  ["tymou__liuxie"] = "谋刘协",
  ["#tymou__liuxie"] = "玉辂东归",
  ["illustrator:tymou__liuxie"] = "黯荧岛",
  ["designer:tymou__liuxie"] = "韩旭",

  ["~tymou__liuxie"] = "前有董贼、李贼，今有曹贼！",
}

--周郎将计：程昱 黄盖
General:new(extension, "tymou__chengyu", "wei", 3):addSkills { "shizha", "gaojian" }
Fk:loadTranslationTable{
  ["tymou__chengyu"] = "谋程昱",
  ["#tymou__chengyu"] = "沐风知秋",
  ["illustrator:tymou__chengyu"] = "匠人绘",

  ["~tymou__chengyu"] = "乌鹊南飞，何枝可依呀……",
}

General:new(extension, "tymou__huanggai", "wu", 4):addSkills { "lieji", "quzhou" }
Fk:loadTranslationTable{
  ["tymou__huanggai"] = "谋黄盖",
  ["#tymou__huanggai"] = "毁身纾难",
  ["illustrator:tymou__huanggai"] = "白",

  ["~tymou__huanggai"] = "被那曹贼看穿了。",
}

return extension
