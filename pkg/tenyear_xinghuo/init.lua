local extension = Package:new("tenyear_xinghuo")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_xinghuo/skills")

Fk:loadTranslationTable{
  ["tenyear_xinghuo"] = "十周年-星火燎原",
  ["ty"] = "新服",
  ["ty_ex"] = "新服界",
}

--天府：星彩 吴苋 孙登 曹昂 诸葛诞 刘协 曹节 步骘
General:new(extension, "ty_ex__sundeng", "wu", 4):addSkills { "ty_ex__kuangbi" }
Fk:loadTranslationTable{
  ["ty_ex__sundeng"] = "界孙登",
  ["#ty_ex__sundeng"] = "才高德茂",
  ["illustrator:ty_ex__sundeng"] = "匠人绘",

  ["~ty_ex__sundeng"] = "此别无期，此恨绵绵。",
}

local zhugedan = General:new(extension, "ty_ex__zhugedan", "wei", 4)
zhugedan:addSkills { "ty_ex__gongao", "ty_ex__juyi" }
zhugedan:addRelatedSkills { "benghuai", "ty_ex__weizhong" }
Fk:loadTranslationTable{
  ["ty_ex__zhugedan"] = "界诸葛诞",
  ["#ty_ex__zhugedan"] = "严毅威重",
  ["illustrator:ty_ex__zhugedan"] = "铁杵文化",

  ["$benghuai_ty_ex__zhugedan"] = "粮尽，援绝，天不佑我。",
  ["~ty_ex__zhugedan"] = "大魏危矣，社稷危矣！",
}

--天梁：董允 诸葛瑾 严畯 李典 司马朗 杜畿 刘焉 张鲁
General:new(extension, "yanjun", "wu", 3):addSkills { "guanchao", "xunxian" }
Fk:loadTranslationTable{
  ["yanjun"] = "严畯",
  ["#yanjun"] = "志存补益",
  ["illustrator:yanjun"] = "YanBai",
  ["cv:yanjun"] = "小思无邪强",

  ["~yanjun"] = "著作，还……没完成……",
}

General:new(extension, "ty__lidian", "wei", 3):addSkills { "xunxun", "ty__wangxi" }
Fk:loadTranslationTable{
  ["ty__lidian"] = "李典",
  ["#ty__lidian"] = "深明大义",
  ["illustrator:ty__lidian"] = "NOVART",

  ["$xunxun_ty__lidian1"] = "吾乃儒雅之士，不需与诸将争功。",
  ["$xunxun_ty__lidian2"] = "读诗书，尚礼仪，守纲常。",
  ["~ty__lidian"] = "恩遇极此，惶恐之至……",
}

General:new(extension, "ty_ex__simalang", "wei", 3):addSkills { "ty_ex__junbing", "ty_ex__quji" }
Fk:loadTranslationTable{
  ["ty_ex__simalang"] = "界司马朗",
  ["#ty_ex__simalang"] = "再世神农",
  --["illustrator:ty_ex__simalang"] = "",

  --["~ty_ex__simalang"] = "",
}

General:new(extension, "duji", "wei", 3):addSkills { "andong", "yingshi" }
Fk:loadTranslationTable{
  ["duji"] = "杜畿",
  ["#duji"] = "卧镇京畿",
  ["illustrator:duji"] = "李秀森",
  ["designer:duji"] = "笔枔",

  ["~duji"] = "试船而溺之，虽亡而忠至。",
}

General:new(extension, "ty_ex__duji", "wei", 3):addSkills { "ty_ex__andong", "ty_ex__yingshi" }
Fk:loadTranslationTable{
  ["ty_ex__duji"] = "界杜畿",
  ["#ty_ex__duji"] = "卧镇京畿",
  ["illustrator:ty_ex__duji"] = "匠人绘",

  ["~ty_ex__duji"] = "公无渡河，公竟渡河。",
}

General:new(extension, "liuyan", "qun", 3):addSkills { "tushe", "limu" }
Fk:loadTranslationTable{
  ["liuyan"] = "刘焉",
  ["#liuyan"] = "裂土之宗",
  ["cv:liuyan"] = "金垚",
  ["designer:liuyan"] = "桃花僧",
  ["illustrator:liuyan"] = "明暗交界",

  ["~liuyan"] = "季玉，望你能守好者益州疆土……",
}
--天机：孙乾 秦宓 薛综 潘濬 戏志才 郭皇后 王粲 蔡邕
General:new(extension, "panjun", "wu", 3):addSkills { "guanwei", "gongqing" }
Fk:loadTranslationTable{
  ["panjun"] = "潘濬",
  ["#panjun"] = "方严疾恶",
  ["illustrator:panjun"] = "秋呆呆",

  ["~panjun"] = "耻失荆州，耻失荆州啊！",
}

General:new(extension, "ty_ex__guohuanghou", "wei", 3, 3, General.Female):addSkills { "ty_ex__jiaozhao", "ty_ex__danxin" }
Fk:loadTranslationTable{
  ["ty_ex__guohuanghou"] = "界郭皇后",
  ["#ty_ex__guohuanghou"] = "月华驱霾",
  ["illustrator:ty_ex__guohuanghou"] = "匠人绘",
  ["cv:ty_ex__guohuanghou"] = "水原",

  ["~ty_ex__guohuanghou"] = "哀家愧对先帝。",
}

General:new(extension, "ty__wangcan", "qun", 3):addSkills { "sanwen", "qiai", "denglou" }
Fk:loadTranslationTable{
  ["ty__wangcan"] = "王粲",
  ["#ty__wangcan"] = "七子之冠冕",
  ["cv:ty__wangcan"] = "安臣杰Anson",
  ["illustrator:ty__wangcan"] = "ZOO",

  ["~ty__wangcan"] = "一作驴鸣悲，万古送葬别。",
}

--天同：SP孙尚香 徐庶 庞统 庞德 蔡文姬 姜维 黄月英 太史慈
local pangtong = General:new(extension, "sp__pangtong", "wu", 3)
pangtong:addSkills { "guolun", "songsang" }
pangtong:addRelatedSkill("zhanji")
Fk:loadTranslationTable{
  ["sp__pangtong"] = "庞统",
  ["#sp__pangtong"] = "南州士冠",
  ["illustrator:sp__pangtong"] = "兴游",

  ["~sp__pangtong"] = "我终究……不得东吴赏识。",
}

General:new(extension, "ty_ex__huangyueying", "qun", 3, 3, General.Female):addSkills { "ty__jiqiao", "ty__linglong" }
Fk:loadTranslationTable{
  ["ty_ex__huangyueying"] = "界黄月英",
  ["#ty_ex__huangyueying"] = "闺中璞玉",
  ["illustrator:ty_ex__huangyueying"] = "匠人绘",

  ["~ty_ex__huangyueying"] = "此心欲留夏，奈何秋风起……",
}

General:new(extension, "sp__taishici", "qun", 4):addSkills { "jixu" }
Fk:loadTranslationTable{
  ["sp__taishici"] = "太史慈",
  ["#sp__taishici"] = "北海酬恩",
  ["illustrator:sp__taishici"] = "王立雄",

  ["~sp__taishici"] = "刘繇之见，短浅也……",
}

General:new(extension, "ty_ex__taishici", "qun", 4):addSkills { "ty_ex__jixu" }
Fk:loadTranslationTable{
  ["ty_ex__taishici"] = "界太史慈",
  ["#ty_ex__taishici"] = "北海酬恩",
  ["illustrator:ty_ex__taishici"] = "匠人绘",

  ["~ty_ex__taishici"] = "危而不救为怯，救而不得为庸。",
}

--天相：李严 糜竺 马忠 周鲂 贺齐 文聘 吕岱 刘繇
General:new(extension, "ty_ex__mazhong", "shu", 4):addSkills { "ty_ex__fuman" }
Fk:loadTranslationTable{
  ["ty_ex__mazhong"] = "界马忠",
  ["#ty_ex__mazhong"] = "笑合南中",
  ["illustrator:ty_ex__mazhong"] = "君桓文化",

  ["~ty_ex__mazhong"] = "愿付此生，见汉蛮一家……",
}

General:new(extension, "zhoufang", "wu", 3):addSkills { "duanfa", "sp__youdi" }
Fk:loadTranslationTable{
  ["zhoufang"] = "周鲂",
  ["#zhoufang"] = "下发载义",
  ["illustrator:zhoufang"] = "黑白画谱",

  ["~zhoufang"] = "功亏一篑，功亏一篑啊。",
}

General:new(extension, "ty_ex__wenpin", "wei", 5):addSkills { "ty_ex__zhenwei" }
Fk:loadTranslationTable{
  ["ty_ex__wenpin"] = "界文聘",
  ["#ty_ex__wenpin"] = "坚城宿将",
  ["illustrator:ty_ex__wenpin"] = "黯荧岛工作室",

  ["~ty_ex__wenpin"] = "没想到，敌军的攻势如此凌厉。",
}

General:new(extension, "lvdai", "wu", 4):addSkills { "qinguo" }
Fk:loadTranslationTable{
  ["lvdai"] = "吕岱",
  ["#lvdai"] = "清身奉公",
  ["illustrator:lvdai"] = "biou09",
  ["designer:lvdai"] = "笔枔",

  ["~lvdai"] = "再也不能，为吴国奉身了。",
}

General:new(extension, "liuyao", "qun", 4):addSkills { "kannan" }
Fk:loadTranslationTable{
  ["liuyao"] = "刘繇",
  ["#liuyao"] = "宗英外镇",
  ["illustrator:liuyao"] = "异酷",

  ["~liuyao"] = "伯符小儿，还我子义！",
}

--七杀：马云騄 关银屏 祖茂 徐氏 吕虔 张梁 蹋顿 公孙瓒
General:new(extension, "lvqian", "wei", 4):addSkills { "weilu", "zengdao" }
Fk:loadTranslationTable{
  ["lvqian"] = "吕虔",
  ["#lvqian"] = "恩威并诸",
  ["illustrator:lvqian"] = "Town",

  ["~lvqian"] = "我自泰山郡以来，百姓获安，镇军伐贼，此生已无憾！",
}

General:new(extension, "zhangliang", "qun", 4):addSkills { "jijun", "fangtong" }
Fk:loadTranslationTable{
  ["zhangliang"] = "张梁",
  ["#zhangliang"] = "人公将军",
  ["illustrator:zhangliang"] = "Town",

  ["~zhangliang"] = "人公也难逃被人所杀……",
}

General:new(extension, "ty_ex__gongsunzan", "qun", 4):addSkills { "ty_ex__qiaomeng", "ty_ex__yicong" }
Fk:loadTranslationTable{
  ["ty_ex__gongsunzan"] = "界公孙瓒",
  ["#ty_ex__gongsunzan"] = "白马将军",
  ["illustrator:ty_ex__gongsunzan"] = "匠人绘",

  ["~ty_ex__gongsunzan"] = "良弓断，白马亡。",
}


return extension
