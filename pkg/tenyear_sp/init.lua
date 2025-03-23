local extension = Package:new("tenyear_sp")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_sp/skills")

Fk:loadTranslationTable{
  ["tenyear_sp"] = "十周年-限定专属",
  ["wm"] = "武",
}

--神武：姜维 马超 张飞 张角 邓艾 许褚 华佗 黄忠 庞统
General:new(extension, "godjiangwei", "god", 4):addSkills { "tianren", "jiufa", "pingxiang" }
Fk:loadTranslationTable{
  ["godjiangwei"] = "神姜维",
  ["#godjiangwei"] = "怒麟布武",
  ["designer:godjiangwei"] = "韩旭",
  ["illustrator:godjiangwei"] = "匠人绘",

  ["~godjiangwei"] = "武侯遗志，已成泡影矣……",
}

General:new(extension, "godmachao", "god", 4):addSkills { "shouli", "hengwu" }
Fk:loadTranslationTable{
  ["godmachao"] = "神马超",
  ["#godmachao"] = "神威天将军",
  ["cv:godmachao"] = "张桐铭", -- 新白张小虾
  ["designer:godmachao"] = "七哀",
  ["illustrator:godmachao"] = "君桓文化",

  ["~godmachao"] = "离群之马，虽强亦亡……",
}

General:new(extension, "godzhangfei", "god", 4):addSkills { "shencai", "xunshi" }
Fk:loadTranslationTable{
  ["godzhangfei"] = "神张飞",
  ["#godzhangfei"] = "两界大巡环使",
  ["designer:godzhangfei"] = "星移",
  ["illustrator:godzhangfei"] = "荧光笔工作室",

  ["~godzhangfei"] = "尔等，欲复斩我头乎？",
}

General:new(extension, "godzhangjiao", "god", 3):addSkills { "yizhao", "sanshou", "sijun", "tianjie" }
Fk:loadTranslationTable{
  ["godzhangjiao"] = "神张角",
  ["#godzhangjiao"] = "末世的起首",
  ["cv:godzhangjiao"] = "虞晓旭",
  ["designer:godzhangjiao"] = "韩旭",
  ["illustrator:godzhangjiao"] = "黯荧岛工作室",

  ["~godzhangjiao"] = "诸君唤我为贼，然我所窃何物？",
}

local goddengai = General:new(extension, "goddengai", "god", 4)
goddengai:addSkills { "tuoyu", "xianjin", "qijing" }
goddengai:addRelatedSkill("cuixin")
Fk:loadTranslationTable{
  ["goddengai"] = "神邓艾",
  ["#goddengai"] = "带砺山河",
  ["designer:goddengai"] = "步穗",
  ["illustrator:goddengai"] = "黯荧岛工作室",

  ["~goddengai"] = "灭蜀者，邓氏士载也！",
}

General:new(extension, "godxuchu", "god", 5):addSkills { "zhengqing", "zhuangpo" }
Fk:loadTranslationTable{
  ["godxuchu"] = "神许褚",
  ["#godxuchu"] = "嗜战的熊罴",
  ["designer:godxuchu"] = "商天害",
  ["illustrator:godxuchu"] = "小新",

  ["~godxuchu"] = "猛虎归林晚，不见往来人……",
}

General:new(extension, "ty__godhuatuo", "god", 3):addSkills { "jingyu", "lvxin", "huandao" }
Fk:loadTranslationTable{
  ["ty__godhuatuo"] = "神华佗",
  ["#ty__godhuatuo"] = "灵魂的医者",
  ["cv:ty__godhuatuo"] = "马洋",
  ["illustrator:ty__godhuatuo"] = "君桓文化",
  ["designer:ty__godhuatuo"] = "韩旭",

  ["~ty__godhuatuo"] = "世无良医，枉死者半……",
}

General:new(extension, "godhuangzhong", "god", 4):addSkills { "lieqiong", "zhanjueh" }
Fk:loadTranslationTable{
  ["godhuangzhong"] = "神黄忠",
  ["#godhuangzhong"] = "战意破苍穹",
  ["illustrator:godhuangzhong"] = "第七个桔子",
  ["designer:godhuangzhong"] = "韩旭",

  ["~godhuangzhong"] = "箭雨曾蔽日，今夕却成绝响。",
}

local godpangtong = General:new(extension, "godpangtong", "god", 1)
godpangtong:addSkills { "luansuo", "fengliao", "kunyu" }
godpangtong.fixMaxHp = 1
Fk:loadTranslationTable{
  ["godpangtong"] = "神庞统",
  ["#godpangtong"] = "丹血浴火",
  ["designer:godpangtong"] = "拔都沙皇",
  ["illustrator:godpangtong"] = "第七个桔子",

  ["~godpangtong"] = "心怀英雄志，何堪寂寥乡……",
}

--祈福：关索 赵襄 鲍三娘 徐荣 曹婴 曹纯 张琪瑛
local guansuo = General:new(extension, "ty__guansuo", "shu", 4)
guansuo:addSkills { "ty__zhengnan", "xiefang" }
guansuo:addRelatedSkills { "ex__wusheng", "ty_ex__dangxian", "ty_ex__zhiman" }
Fk:loadTranslationTable{
  ["ty__guansuo"] = "关索",
  ["#ty__guansuo"] = "倜傥孑侠",
  ["illustrator:ty__guansuo"] = "第七个桔子",

  ["$ex__wusheng_ty__guansuo"] = "我敬佩你的勇气。",
  ["$ty_ex__dangxian_ty__guansuo"] = "时时居先，方可快人一步。",
  ["$ty_ex__zhiman_ty__guansuo"] = "败军之将，自当纳贡！",
  ["~ty__guansuo"] = "索，至死不辱家风！",
}

General:new(extension, "ty__zhaoxiang", "shu", 4, 4, General.Female):addSkills { "ty__fanghun", "ty__fuhan" }
Fk:loadTranslationTable{
  ["ty__zhaoxiang"] = "赵襄",
  ["#ty__zhaoxiang"] = "拾梅鹊影",
  ["cv:ty__zhaoxiang"] = "闲踏梧桐",
  ["illustrator:ty__zhaoxiang"] = "木美人",

  ["~ty__zhaoxiang"] = "此生为汉臣，死为汉芳魂……",
}

local baosanniang = General:new(extension, "ty__baosanniang", "shu", 3, 3, General.Female)
baosanniang:addSkills { "ty__wuniang", "ty__xushen" }
baosanniang:addRelatedSkill("ty__zhennan")
Fk:loadTranslationTable{
  ["ty__baosanniang"] = "鲍三娘",
  ["#ty__baosanniang"] = "南中武娘",
  ["illustrator:ty__baosanniang"] = "DH",

  ["~ty__baosanniang"] = "彼岸花开红似火，花期苦短终别离……",
}

General:new(extension, "xurong", "qun", 4):addSkills { "xionghuo", "shajue" }
Fk:loadTranslationTable{
  ["xurong"] = "徐荣",
  ["#xurong"] = "玄菟战魔",
  ["cv:xurong"] = "曹真",
  ["designer:xurong"] = "Loun老萌",
  ["illustrator:xurong"] = "zoo",

  ["~xurong"] = "此生无悔，心中无愧。",
}

General:new(extension, "ty__caochun", "wei", 4):addSkills { "ty__shanjia" }
Fk:loadTranslationTable{
  ["ty__caochun"] = "曹纯",
  ["#ty__caochun"] = "虎豹骑首",
  ["illustrator:ty__caochun"] = "凡果_Make",

  ["~ty__caochun"] = "不胜即亡，唯一死而已！",
}

General:new(extension, "zhangqiying", "qun", 3, 3, General.Female):addSkills { "falu", "zhenyi", "dianhua" }
Fk:loadTranslationTable{
  ["zhangqiying"] = "张琪瑛",
  ["#zhangqiying"] = "禳祷西东",
  ["illustrator:zhangqiying"] = "alien",

  ["~zhangqiying"] = "米碎面散，我心欲绝……",
}

--隐山之玉：周夷 卢弈 孙翎鸾 曹轶 庞凤衣
local zhouyi = General:new(extension, "zhouyi", "wu", 3, 3, General.Female)
zhouyi:addSkills { "zhukou", "mengqing" }
zhouyi:addRelatedSkill("yuyun")
Fk:loadTranslationTable{
  ["zhouyi"] = "周夷",
  ["#zhouyi"] = "靛情雨黛",
  ["illustrator:zhouyi"] = "Tb罗根",

  ["~zhouyi"] = "江水寒，萧瑟起……",
}

local luyi = General:new(extension, "luyi", "qun", 3, 3, General.Female)
luyi:addSkills { "fuxue", "yaoyi" }
luyi:addRelatedSkill("shoutan")
Fk:loadTranslationTable{
  ["luyi"] = "卢弈",
  ["#luyi"] = "落子惊鸿",
  ["designer:luyi"] = "星移",
  ["illustrator:luyi"] = "匠人绘",

  ["~luyi"] = "此生博弈，落子未有悔……",
}

General:new(extension, "sunlingluan", "wu", 3, 3, General.Female):addSkills { "lingyue", "pandi" }
Fk:loadTranslationTable{
  ["sunlingluan"] = "孙翎鸾",
  ["#sunlingluan"] = "弦凤栖梧",
  ["designer:sunlingluan"] = "星移",
  ["illustrator:sunlingluan"] = "HEI-LEI",

  ["~sunlingluan"] = "良人当归，苦酒何妨……",
}

General:new(extension, "caoyi", "wei", 4, 4, General.Female):addSkills { "miyi", "yinjun" }
Fk:loadTranslationTable{
  ["caoyi"] = "曹轶",
  ["#caoyi"] = "飒姿缔燹",
  ["illustrator:caoyi"] = "匠人绘",
  ["designer:caoyi"] = "星移",

  ["~caoyi"] = "霜落寒鸦浦，天下无故人……",
}

General:new(extension, "pangfengyi", "shu", 3, 3, General.Female):addSkills { "yitong", "peiniang" }
Fk:loadTranslationTable{
  ["pangfengyi"] = "庞凤衣",
  ["#pangfengyi"] = "瞳悉万机",
  ["designer:pangfengyi"] = "星移",
  ["illustrator:pangfengyi"] = "黯荧岛",

  ["~pangfengyi"] = "我为这大火，再添一坛烈酒如何？",
}

--高山仰止：王朗 刘徽
--武庙：诸葛亮 陆逊 关羽

return extension
