local extension = Package:new("tenyear_huicui")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_huicui/skills")

Fk:loadTranslationTable{
  ["tenyear_huicui"] = "十周年-群英荟萃",
  ["ty_sp"] = "新服SP",
  ["mu"] = "乐",
}

--黄巾之乱：韩遂√ 刘宏√ 朱儁√ 许劭√
General:new(extension, "ty__hansui", "qun", 4):addSkills { "ty__niluan", "weiwu" }
Fk:loadTranslationTable{
  ["ty__hansui"] = "韩遂",
  ["#ty__hansui"] = "雄踞北疆",
  ["illustrator:ty__hansui"] = "凝聚永恒",

  ["~ty__hansui"] = "马侄儿为何？啊！！",
}

local liuhong = General:new(extension, "ty__liuhong", "qun", 4)
liuhong:addSkills { "yujue", "tuxing" }
liuhong:addRelatedSkill("zhihu")
Fk:loadTranslationTable{
  ["ty__liuhong"] = "刘宏",
  ["#ty__liuhong"] = "汉灵帝",
  ["cv:ty__liuhong"] = "贾志超219",
  ["illustrator:ty__liuhong"] = "凝聚永恒",
  ["designer:ty__liuhong"] = "笔枔",

  ["~ty__liuhong"] = "权利的滋味，让人沉沦。",
}

General:new(extension, "ty__zhujun", "qun", 4):addSkills { "gongjian", "kuimang" }
Fk:loadTranslationTable{
  ["ty__zhujun"] = "朱儁",
  ["#ty__zhujun"] = "征无疑虑",
  ["illustrator:ty__zhujun"] = "凝聚永恒",

  ["~ty__zhujun"] = "乞降不受，愿一战！",
}

General:new(extension, "ty__xushao", "qun", 4):addSkills { "ty__pingjian" }
Fk:loadTranslationTable{
  ["ty__xushao"] = "许劭",
  ["#ty__xushao"] = "识人读心",
  ["designer:ty__xushao"] = "韩旭",
  ["cv:ty__xushao"] = "冷泉夜月",
  ["illustrator:ty__xushao"] = "Thinking",

  ["~ty__xushao"] = "守节好耻，不可逡巡……",
}

--诸侯伐董：丁原√ 王荣√ 麹义√ 韩馥√
local dingyuan = General:new(extension, "ty__dingyuan", "qun", 4)
dingyuan:addSkills { "cixiao", "xianshuai" }
dingyuan:addRelatedSkill("panshi")
Fk:loadTranslationTable{
  ["ty__dingyuan"] = "丁原",
  ["#ty__dingyuan"] = "养虎为患",
  ["cv:ty__dingyuan"] = "贾志超219",
  ["illustrator:ty__dingyuan"] = "秋呆呆",

  ["~ty__dingyuan"] = "你我父子，此恩今日断！",
}

General:new(extension, "ty__wangrongh", "qun", 3, 3, General.Female):addSkills { "minsi", "jijing", "zhuide" }
Fk:loadTranslationTable{
  ["ty__wangrongh"] = "王荣",
  ["#ty__wangrongh"] = "灵怀皇后",
  ["illustrator:ty__wangrongh"] = "福州明暗",

  ["~ty__wangrongh"] = "谁能护妾身幼子……",
}

General:new(extension, "ty__quyi", "qun", 4):addSkills { "ty__fuji", "jiaozi" }
Fk:loadTranslationTable{
  ["ty__quyi"] = "麴义",
  ["#ty__quyi"] = "名门的骁将",
  ["illustrator:ty__quyi"] = "目游",

  ["$jiaozi_ty__quyi1"] = "今日之获，皆是吾之功劳。",
  ["$jiaozi_ty__quyi2"] = "今吾于此，尔等皆为飞灰！",
  ["~ty__quyi"] = "我为主公戎马一生，主公为何如此对我……",
}

General:new(extension, "hanfu", "qun", 4):addSkills { "jieyingh", "ty__weipo" }
Fk:loadTranslationTable{
  ["hanfu"] = "韩馥",
  ["#hanfu"] = "度势恇然",
  ["illustrator:hanfu"] = "福州明暗",

  ["~hanfu"] = "袁本初，你为何不放过我！",
}

--徐州风云：陶谦√ 曹嵩√ 张邈√ 丘力居√
General:new(extension, "ty__taoqian", "qun", 4):addSkills { "zhaohuo", "ty__yixiang", "ty__yirang" }
Fk:loadTranslationTable{
  ["ty__taoqian"] = "陶谦",
  ["#ty__taoqian"] = "膺秉温仁",
  ["illustrator:ty__taoqian"] = "福州明暗",

  ["$zhaohuo_ty__taoqian1"] = "覆巢之下，安有完卵。",
  ["$zhaohuo_ty__taoqian2"] = "四战之地，兵连祸结。",
  ["~ty__taoqian"] = "原知万事空，谁解托州意？",
}

General:new(extension, "ty__caosong", "wei", 4):addSkills { "lilu", "yizhengc" }
Fk:loadTranslationTable{
  ["ty__caosong"] = "曹嵩",
  ["#ty__caosong"] = "依权弼子",
  ["designer:ty__caosong"] = "步穗",
  ["illustrator:ty__caosong"] = "凝聚永恒",

  ["~ty__caosong"] = "孟德，勿忘汝父之仇！",
}

local zhangmiao = General:new(extension, "zhangmiao", "qun", 4)
zhangmiao:addSkills { "mouni", "zongfan" }
zhangmiao:addRelatedSkill("zhangu")
Fk:loadTranslationTable{
  ["zhangmiao"] = "张邈",
  ["#zhangmiao"] = "苔岑往却",
  ["designer:zhangmiao"] = "步穗",
  ["illustrator:zhangmiao"] = "猎枭",

  ["~zhangmiao"] = "独木终难支矣。",
}

General:new(extension, "qiuliju", "qun", 4, 6):addSkills { "koulue", "suirenq" }
Fk:loadTranslationTable{
  ["qiuliju"] = "丘力居",
  ["#qiuliju"] = "乌丸王",
  ["illustrator:qiuliju"] = "盲特",

  ["~qiuliju"] = "乌丸危矣！",
}

--中原狼烟：董承√ 胡车儿√ 邹氏√ 曹安民√
General:new(extension, "ty__dongcheng", "qun", 4):addSkills { "xuezhao" }
Fk:loadTranslationTable{
  ["ty__dongcheng"] = "董承",
  ["#ty__dongcheng"] = "扬义誓诛",
  ["designer:ty__dongcheng"] = "步穗",
  ["illustrator:ty__dongcheng"] = "游漫美绘",

  ["~ty__dongcheng"] = "是谁走漏了风声？",
}

General:new(extension, "ty__hucheer", "qun", 4):addSkills { "ty__daoji", "fuzhong" }
Fk:loadTranslationTable{
  ["ty__hucheer"] = "胡车儿",
  ["#ty__hucheer"] = "惩奸除恶",
  ["illustrator:ty__hucheer"] = "游漫美绘",
  ["designer:ty__hucheer"] = "韩旭",

  ["~ty__hucheer"] = "好快的涯角枪！",
}

General:new(extension, "ty__zoushi", "qun", 3, 3, General.Female):addSkills { "ty__huoshui", "ty__qingcheng" }
Fk:loadTranslationTable{
  ["ty__zoushi"] = "邹氏",
  ["#ty__zoushi"] = "惑心之魅",
  ["illustrator:ty__zoushi"] = "猎枭",

  ["~ty__zoushi"] = "年老色衰了吗……",
}

General:new(extension, "caoanmin", "wei", 4):addSkills { "xianwei" }
Fk:loadTranslationTable{
  ["caoanmin"] = "曹安民",
  ["#caoanmin"] = "履薄临深",
  ["illustrator:caoanmin"] = "君桓文化",

  ["~caoanmin"] = "伯父快走！",
}

--虓虎悲歌：郝萌√ 严夫人√ 朱灵√ 阎柔√
General:new(extension, "ty__haomeng", "qun", 7):addSkills { "xiongmang" }
Fk:loadTranslationTable{
  ["ty__haomeng"] = "郝萌",
  ["#ty__haomeng"] = "悖虎之伥",
  ["cv:ty__haomeng"] = "虞晓旭",
  ["illustrator:ty__haomeng"] = "猎枭",

  ["~ty__haomeng"] = "曹性，汝欲反我不成？",
}

General:new(extension, "yanfuren", "qun", 3, 3, General.Female):addSkills { "channi", "nifu" }
Fk:loadTranslationTable{
  ["yanfuren"] = "严夫人",
  ["#yanfuren"] = "霜天薄裳",
  ["cv:yanfuren"] = "亦喵酱",
  ["illustrator:yanfuren"] = "君桓文化",

  ["~yanfuren"] = "妾身绝不会害将军呀！",
}

General:new(extension, "ty__zhuling", "wei", 4):addSkills { "ty__zhanyi" }
Fk:loadTranslationTable{
  ["ty__zhuling"] = "朱灵",
  ["#ty__zhuling"] = "良将之亚",
  ["illustrator:ty__zhuling"] = "XXX&Karneval",

  ["~ty__zhuling"] = "吾，错付曹公……",
}

General:new(extension, "yanrou", "wei", 4):addSkills { "choutao", "xiangshu" }
Fk:loadTranslationTable{
  ["yanrou"] = "阎柔",
  ["#yanrou"] = "冠玉啸北",
  ["illustrator:yanrou"] = "凝聚永恒",

  ["~yanrou"] = "寒风折戍矛，铁衣裹枯骨……",
}

--群雄伺动：严白虎x
--文和乱武：李傕√ 郭汜√ 樊稠√ 张济√ 梁兴√ 唐姬√ 段煨√ 张横√ 牛辅√ 董翓√ 李傕郭汜√
General:new(extension, "lijue", "qun", 4, 6):addSkills { "langxi", "yisuan" }
Fk:loadTranslationTable{
  ["lijue"] = "李傕",
  ["#lijue"] = "奸谋恶勇",
  ["illustrator:lijue"] = "小牛",

  ["~lijue"] = "若无内讧，也不至如此。",
}

General:new(extension, "guosi", "qun", 4):addSkills { "tanbei", "sidao" }
Fk:loadTranslationTable{
  ["guosi"] = "郭汜",
  ["#guosi"] = "党豺为虐",
  ["cv:guosi"] = "曹真",
  ["illustrator:guosi"] = "秋呆呆",

  ["~guosi"] = "伍习，你……",
}

General:new(extension, "fanchou", "qun", 4):addSkills { "xingluan" }
Fk:loadTranslationTable{
  ["fanchou"] = "樊稠",
  ["#fanchou"] = "庸生变难",
  ["illustrator:fanchou"] = "天纵世纪",

  ["~fanchou"] = "唉，稚然，疑心甚重。",
}

General:new(extension, "zhangji", "qun", 4):addSkills { "lueming", "tunjun" }
Fk:loadTranslationTable{
  ["zhangji"] = "张济",
  ["#zhangji"] = "武威雄豪",
  ["illustrator:zhangji"] = "YanBai",

  ["~zhangji"] = "哪，哪里来的乱箭？",
}

General:new(extension, "liangxing", "qun", 4):addSkills { "lulue", "zhuixi" }
Fk:loadTranslationTable{
  ["liangxing"] = "梁兴",
  ["#liangxing"] = "凶豺掠豹",
  ["cv:liangxing"] = "虞晓旭",
  ["illustrator:liangxing"] = "匠人绘",

  ["~liangxing"] = "夏侯渊，你竟敢！",
}

General:new(extension, "tangji", "qun", 3, 3, General.Female):addSkills { "kangge", "jielie" }
Fk:loadTranslationTable{
  ["tangji"] = "唐姬",
  ["#tangji"] = "弘农王妃",
  ["cv:tangji"] = "Z君不吃番茄",
  ["illustrator:tangji"] = "福州明暗",

  ["~tangji"] = "皇天崩兮后土颓……",
}

General:new(extension, "duanwei", "qun", 4):addSkills { "ty__langmie" }
Fk:loadTranslationTable{
  ["duanwei"] = "段煨",
  ["#duanwei"] = "凉国之英",
  ["cv:duanwei"] = "虞晓旭",
  ["illustrator:duanwei"] = "匠人绘",

  ["~duanwei"] = "禀赡天子，终无二意。",
}

General:new(extension, "zhangheng", "qun", 8):addSkills { "liangjue", "dangzai" }
Fk:loadTranslationTable{
  ["zhangheng"] = "张横",
  ["#zhangheng"] = "戾鹘枭鹰",
  ["illustrator:zhangheng"] = "匠人绘",

  ["~zhangheng"] = "军粮匮乏。",
}

General:new(extension, "niufu", "qun", 4, 7):addSkills { "xiaoxix", "xiongrao" }
Fk:loadTranslationTable{
  ["niufu"] = "牛辅",
  ["#niufu"] = "魔郎",
  ["illustrator:niufu"] = "福州明暗",

  ["~niufu"] = "胡儿安敢杀我！",
}

General:new(extension, "dongxie", "qun", 4, 4, General.Female):addSkills { "jiaoxia", "humei" }
Fk:loadTranslationTable{
  ["dongxie"] = "董翓",
  ["#dongxie"] = "暗夜豺狐",
  ["designer:dongxie"] = "步穗",
  ["illustrator:dongxie"] = "凝聚永恒",

  ["~dongxie"] = "覆巢之下，断无完卵余生……",
}

General:new(extension, "ty__lijueguosi", "qun", 4):addSkills { "ty__xiongsuan" }
Fk:loadTranslationTable{
  ["ty__lijueguosi"] = "李傕郭汜",
  ["#ty__lijueguosi"] = "犯祚倾祸",
  ["illustrator:ty__lijueguosi"] = "君桓文化",

  ["~ty__lijueguosi"] = "异心相争，兵败战损。",
}

--逐鹿天下：张恭√ 吕凯√ 卫温诸葛直√ 卑弥呼x
General:new(extension, "zhanggong", "wei", 3):addSkills { "qianxinz", "zhenxing" }
Fk:loadTranslationTable{
  ["zhanggong"] = "张恭",
  ["#zhanggong"] = "西域长歌",
  ["illustrator:zhanggong"] = "B_LEE",
  ["designer:zhanggong"] = "笔枔",

  ["~zhanggong"] = "边关失守，我之过失！",
}

General:new(extension, "lvkai", "shu", 3):addSkills { "tunan", "bijing" }
Fk:loadTranslationTable{
  ["lvkai"] = "吕凯",
  ["#lvkai"] = "铁心司南",
  ["designer:lvkai"] = "世外高v狼",
  ["illustrator:lvkai"] = "大佬荣&alien",

  ["~lvkai"] = "守节不易，吾愿舍身为蜀。",
}

General:new(extension, "weiwenzhugezhi", "wu", 4):addSkills { "fuhaiw" }
Fk:loadTranslationTable{
  ["weiwenzhugezhi"] = "卫温诸葛直",
  ["#weiwenzhugezhi"] = "帆至夷洲",
  ["designer:weiwenzhugezhi"] = "桃花僧",
  ["illustrator:weiwenzhugezhi"] = "秋呆呆",

  ["~weiwenzhugezhi"] = "吾皆海岱清士，岂料生死易逝……",
}

--食禄尽忠：沙摩柯√ 忙牙长√ 许贡√ 张昌蒲√
General:new(extension, "shamoke", "shu", 4):addSkills { "jilis" }
Fk:loadTranslationTable{
  ["shamoke"] = "沙摩柯",
  ["#shamoke"] = "五溪蛮夷",
  ["illustrator:shamoke"] = "Ray",

  ["~shamoke"] = "五溪蛮夷，不可能输！",
}

General:new(extension, "mangyachang", "qun", 4):addSkills { "jiedao" }
Fk:loadTranslationTable{
  ["mangyachang"] = "忙牙长",
  ["#mangyachang"] = "截头蛮锋",
  ["illustrator:mangyachang"] = "北★MAN",

  ["~mangyachang"] = "黄骠马也跑不快了……",
}

General:new(extension, "ty__xugong", "wu", 3):addSkills { "biaozhao", "yechou" }
Fk:loadTranslationTable{
  ["ty__xugong"] = "许贡",
  ["#ty__xugong"] = "独计击流",
  ["illustrator:ty__xugong"] = "红字虾",

  ["~ty__xugong"] = "终究……还是被其所害……",
}

General:new(extension, "ty__zhangchangpu", "wei", 3, 3, General.Female):addSkills { "yanjiao", "xingshen" }
Fk:loadTranslationTable{
  ["ty__zhangchangpu"] = "张昌蒲",
  ["#ty__zhangchangpu"] = "矜严明训",
  ["designer:ty__zhangchangpu"] = "韩旭",
  ["illustrator:ty__zhangchangpu"] = "biou09",

  ["~ty__zhangchangpu"] = "我还是小看了，孙氏的伎俩……",
}

--戚宦之争：张让√ 何进√ 何太后 冯方√ 赵忠√ 穆顺√ 伏完
General:new(extension, "ty__zhangrang", "qun", 3):addSkills { "ty__taoluan" }
Fk:loadTranslationTable{
  ["ty__zhangrang"] = "张让",
  ["#ty__zhangrang"] = "窃幸绝禋",
  ["designer:ty__zhangrang"] = "千幻",
  ["illustrator:ty__zhangrang"] = "zoo",

  ["~ty__zhangrang"] = "尽失权柄，我等难容于天下！",
}

General:new(extension, "ty__hejin", "qun", 4):addSkills { "ty__mouzhu", "ty__yanhuo" }
Fk:loadTranslationTable{
  ["ty__hejin"] = "何进",
  ["#ty__hejin"] = "色厉内荏",
  ["cv:ty__hejin"] = "冷泉夜月",
  ["illustrator:ty__hejin"] = "凝聚永恒",

  ["~ty__hejin"] = "诛宦不成，反遭其害，遗笑天下人矣……",
}

General:new(extension, "fengfang", "qun", 3):addSkills { "diting", "bihuo" }
Fk:loadTranslationTable{
  ["fengfang"] = "冯方",
  ["#fengfang"] = "监彻京师",
  ["designer:fengfang"] = "梦魇狂朝",
  ["illustrator:fengfang"] = "游漫美绘",

  ["~fengfang"] = "掌控校事，为人所忌。",
}

General:new(extension, "zhaozhong", "qun", 6):addSkills { "yangzhong", "huangkong" }
Fk:loadTranslationTable{
  ["zhaozhong"] = "赵忠",
  ["#zhaozhong"] = "骄纵窃幸",
  ["cv:zhaozhong"] = "贾志超219",
  ["illustrator:zhaozhong"] = "MUMU",

  ["~zhaozhong"] = "咱家忠心可鉴啊！！",
}

General:new(extension, "mushun", "qun", 4):addSkills { "jinjianm", "shizhao" }
Fk:loadTranslationTable{
  ["mushun"] = "穆顺",
  ["#mushun"] = "疾风劲草",
  ["illustrator:mushun"] = "君桓文化",

  ["~mushun"] = "这，何来的大风？",
}

--上兵伐谋：辛毗√ 伊籍x 张温√ 李肃√
General:new(extension, "xinpi", "wei", 3):addSkills { "chijie", "yinju" }
Fk:loadTranslationTable{
  ["xinpi"] = "辛毗",
  ["#xinpi"] = "一节肃六军",
  ["illustrator:xinpi"] = "石蝉",
  ["designer:xinpi"] = "神壕",

  ["~xinpi"] = "失民心，且无食。",
}

General:new(extension, "ty__zhangwen", "wu", 3):addSkills { "ty__songshu", "sibian" }
Fk:loadTranslationTable{
  ["ty__zhangwen"] = "张温",
  ["#ty__zhangwen"] = "冲天孤鹭",
  ["illustrator:ty__zhangwen"] = "zoo",

  ["~ty__zhangwen"] = "暨艳过错，强牵吾罪。",
}

General:new(extension, "ty__lisu", "qun", 2):addSkills { "lixun", "kuizhul" }
Fk:loadTranslationTable{
  ["ty__lisu"] = "李肃",
  ["#ty__lisu"] = "魔使",
  ["illustrator:ty__lisu"] = "alien",

  ["~ty__lisu"] = "金银珠宝再多，也难买命啊。",
}

--兵临城下：牛金√ 糜芳傅士仁√ 李采薇√ 赵俨√ 王威√ 李异谢旌√ 孙桓√ 孟达√ 是仪√ 孙狼√
General:new(extension, "ty__niujin", "wei", 4):addSkills { "cuirui", "ty__liewei" }
Fk:loadTranslationTable{
  ["ty__niujin"] = "牛金",
  ["#ty__niujin"] = "独进的兵胆",
  ["illustrator:ty__niujin"] = "游漫美绘",

  ["~ty__niujin"] = "这酒有毒！",
}

General:new(extension, "ty__mifangfushiren", "shu", 4):addSkills { "ty__fengshih" }
Fk:loadTranslationTable{
  ["ty__mifangfushiren"] = "糜芳傅士仁",
  ["#ty__mifangfushiren"] = "进退维谷",
  ["illustrator:ty__mifangfushiren"] = "游漫美绘",

  ["~ty__mifangfushiren"] = "愧对将军。",
}

General:new(extension, "licaiwei", "qun", 3, 3, General.Female):addSkills { "yijiao", "qibie" }
Fk:loadTranslationTable{
  ["licaiwei"] = "李采薇",
  ["#licaiwei"] = "啼雨孤鸯",
  ["illustrator:licaiwei"] = "Jzeo",

  ["~licaiwei"] = "随君而去……",
}

General:new(extension, "ty__zhaoyan", "wei", 3):addSkills { "funing", "bingji" }
Fk:loadTranslationTable{
  ["ty__zhaoyan"] = "赵俨",
  ["#ty__zhaoyan"] = "扬历干功",
  ["cv:ty__zhaoyan"] = "冰霜墨菊",
  ["illustrator:ty__zhaoyan"] = "游漫美绘",
  ["designer:ty__zhaoyan"] = "追风青年",

  ["~ty__zhaoyan"] = "背信食言，当有此劫……",
}

General:new(extension, "wangwei", "qun", 4):addSkills { "ruizhan", "shilie" }
Fk:loadTranslationTable{
  ["wangwei"] = "王威",
  ["#wangwei"] = "苍心辟道",
  ["illustrator:wangwei"] = "荧光笔工作室",

  ["~wangwei"] = "后有追兵，主公先行！",
}

General:new(extension, "liyixiejing", "wu", 4):addSkills { "douzhen" }
Fk:loadTranslationTable{
  ["liyixiejing"] = "李异谢旌",
  ["#liyixiejing"] = "踵蹑袭进",
  ["designer:liyixiejing"] = "七哀",
  ["illustrator:liyixiejing"] = "匠人绘",

  ["~liyixiejing"] = "蜀军凶猛，虽力战犹不敌……",
}

General:new(extension, "sunhuan", "wu", 4):addSkills { "niji" }
Fk:loadTranslationTable{
  ["sunhuan"] = "孙桓",
  ["#sunhuan"] = "扼龙决险",
  ["designer:sunhuan"] = "坑坑",
  ["illustrator:sunhuan"] = "一意动漫",

  ["~sunhuan"] = "此建功立业之时，奈何……",
}

local mengda = General:new(extension, "ty__mengda", "wei", 4)
mengda.subkingdom = "shu"
mengda:addSkills { "libang", "wujie" }
Fk:loadTranslationTable{
  ["ty__mengda"] = "孟达",
  ["#ty__mengda"] = "据国向己",
  ["designer:ty__mengda"] = "傍晚的水豚巴士",
  ["illustrator:ty__mengda"] = "六道目",

  ["~ty__mengda"] = "司马老贼害我，诸葛老贼误我……",
}

local shiyi = General:new(extension, "shiyi", "wu", 3)
shiyi:addSkills { "cuichuan", "zhengxu" }
shiyi:addRelatedSkill("zuojian")
Fk:loadTranslationTable{
  ["shiyi"] = "是仪",
  ["#shiyi"] = "清恪贞佐",
  ["designer:shiyi"] = "神壕",
  ["illustrator:shiyi"] = "福州乐战",

  ["~shiyi"] = "吾故后，务从省约……",
}

General:new(extension, "sunlang", "shu", 4):addSkills { "tingxian", "benshi" }
Fk:loadTranslationTable{
  ["sunlang"] = "孙狼",
  ["#sunlang"] = "恶惮远役",
  ["designer:sunlang"] = "残昼厄夜",
  ["illustrator:sunlang"] = "六道目",

  ["~sunlang"] = "为关将军死，无憾……",
}

--千里单骑：魏关羽√ 杜夫人√ 秦宜禄√ 卞喜√ 胡班√ 胡金定√ 关宁√
local guanyu = General:new(extension, "ty_sp__guanyu", "wei", 4)
guanyu:addSkills { "ex__wusheng", "ty__danji" }
guanyu:addRelatedSkills { "mashu", "nuchen" }
Fk:loadTranslationTable{
  ["ty_sp__guanyu"] = "关羽",
  ["#ty_sp__guanyu"] = "汉寿亭侯",
  ["designer:ty_sp__guanyu"] = "韩旭",
  ["illustrator:ty_sp__guanyu"] = "写之火工作室",

  ["$ex__wusheng_ty_sp__guanyu1"] = "以义传魂，以武入圣！",
  ["$ex__wusheng_ty_sp__guanyu2"] = "义击逆流，武安黎庶。",
  ["~ty_sp__guanyu"] = "樊城一去，死亦无惧……",
}

General:new(extension, "dufuren", "wei", 3, 3, General.Female):addSkills { "yise", "shunshi" }
Fk:loadTranslationTable{
  ["dufuren"] = "杜夫人",
  ["#dufuren"] = "沛王太妃",
  ["designer:dufuren"] = "步穗",
  ["illustrator:dufuren"] = "匠人绘",

  ["~dufuren"] = "往事云烟，去日苦多。",
}

General:new(extension, "qinyilu", "qun", 3):addSkills { "piaoping", "tuoxian", "zhuili" }
Fk:loadTranslationTable{
  ["qinyilu"] = "秦宜禄",
  ["#qinyilu"] = "尘垢粃糠",
  ["designer:qinyilu"] = "追风少年",
  ["illustrator:qinyilu"] = "君桓文化",

  ["~qinyilu"] = "我竟落得如此下场……",
}

General:new(extension, "bianxi", "wei", 4):addSkills { "dunxi" }
Fk:loadTranslationTable{
  ["bianxi"] = "卞喜",
  ["#bianxi"] = "伏龛蛇影",
  ["illustrator:bianxi"] = "君桓文化",

  ["~bianxi"] = "以力破巧，难挡其锋……",
}

General:new(extension, "ty__huban", "wei", 4):addSkills { "chongyi" }
Fk:loadTranslationTable{
  ["ty__huban"] = "胡班",
  ["#ty__huban"] = "血火照路",
  ["designer:ty__huban"] = "世外高v狼",
  ["illustrator:ty__huban"] = "君桓文化",

  ["~ty__huban"] = "行义而亡，虽死无憾。",
}

General:new(extension, "ty__hujinding", "shu", 3, 6, General.Female):addSkills { "deshi", "ty__wuyuan", "huaizi" }
Fk:loadTranslationTable{
  ["ty__hujinding"] = "胡金定",
  ["#ty__hujinding"] = "怀子求怜",
  ["illustrator:ty__hujinding"] = "匠人绘",

  ["~ty__hujinding"] = "妾不畏死，唯畏君断情。",
}

General:new(extension, "guannings", "shu", 3):addSkills { "xiuwen", "longsong" }
Fk:loadTranslationTable{
  ["guannings"] = "关宁",
  ["#guannings"] = "承义秉文",
  ["designer:guannings"] = "韩旭",
  ["illustrator:guannings"] = "黯荧岛工作室",

  ["~guannings"] = "为国捐生，虽死无憾……",
}

--烽火连天：南华老仙√ 童渊√ 张宁√ 庞德公√
local nanhualaoxian = General:new(extension, "ty__nanhualaoxian", "qun", 4)
nanhualaoxian:addSkills { "gongxiu", "jinghe" }
nanhualaoxian:addRelatedSkills { "ex__leiji", "yinbingn", "huoqi", "guizhu", "xianshou", "lundao",
  "guanyue", "yanzhengn", "ex__biyue", "ex__tuxi", "ty_ex__mingce", "ty_ex__zhiyan" }
Fk:loadTranslationTable{
  ["ty__nanhualaoxian"] = "南华老仙",
  ["#ty__nanhualaoxian"] = "仙人指路",
  ["illustrator:ty__nanhualaoxian"] = "君桓文化",
  ["cv:ty__nanhualaoxian"] = "大许哥",

  ["~ty__nanhualaoxian"] = "道亦有穷时……",
}

local tongyuan = General:new(extension, "ty__tongyuan", "qun", 4)
tongyuan:addSkills { "chaofeng", "chuanshu" }
tongyuan:addRelatedSkills { "longdan", "congjian", "chuanyun" }
Fk:loadTranslationTable{
  ["ty__tongyuan"] = "童渊",
  ["#ty__tongyuan"] = "蓬莱枪神散人",
  ["illustrator:ty__tongyuan"] = "目游",
  ["cv:ty__tongyuan"] = "大白siro",

  ["$longdan_ty__tongyuan"] = "能进能退，方显名将本色。",
  ["$congjian_ty__tongyuan"] = "察言纳谏，安身立命之道也。",
  ["~ty__tongyuan"] = "一门三杰，无憾矣！",
}

General:new(extension, "ty__zhangning", "qun", 3, 3, General.Female):addSkills { "tianze", "difa" }
Fk:loadTranslationTable{
  ["ty__zhangning"] = "张宁",
  ["#ty__zhangning"] = "大贤后人",
  ["illustrator:ty__zhangning"] = "君桓文化",

  ["~ty__zhangning"] = "全气之地，当葬其止……",
}

General:new(extension, "ty__pangdegong", "qun", 3):addSkills { "heqia", "yinyi" }
Fk:loadTranslationTable{
  ["ty__pangdegong"] = "庞德公",
  ["#ty__pangdegong"] = "友睦风疏",
  ["cv:ty__pangdegong"] = "大白siro", -- 本名：陈伟
  ["designer:ty__pangdegong"] = "步穗",
  ["illustrator:ty__pangdegong"] = "君桓文化",

  ["~ty__pangdegong"] = "终无可避……",
}

--无双上将：潘凤 邢道荣 曹性 淳于琼 夏侯杰 蔡阳 周善
--才子佳人：董白 何晏 孙鲁育 王桃 王悦 赵嫣 滕胤 张嫙 夏侯令女 孙茹 蒯祺 庞山民 张媱 孔融
--芝兰玉树：张虎 吕玲绮 刘永 黄舞蝶 万年公主 滕公主 庞会 赵统赵广 袁尚袁谭袁熙 乐綝 刘理 庞宏

--天下归心：阚泽√ 魏贾诩√ 陈登√ 蔡瑁张允√ 高览√ 尹夫人√ 吕旷吕翔√ 陈珪√ 陈矫√ 秦朗√ 董昭√ 侯成√ 唐咨√ 臧霸√ 乐进√ 曹洪x
General:new(extension, "ty__kanze", "wu", 3):addSkills { "xiashu", "ty__kuanshi" }
Fk:loadTranslationTable{
  ["ty__kanze"] = "阚泽",
  ["#ty__kanze"] = "慧眼的博士",
  ["illustrator:ty__kanze"] = "游漫美绘",

  ["$xiashu_ty__kanze1"] = "吾等诚心归降，天地可鉴。",
  ["$xiashu_ty__kanze2"] = "公与我里应外合，则大事可成。",
  ["~ty__kanze"] = "唉，计谋败露，吾命休矣。",
}

General:new(extension, "ty__jiaxu", "wei", 3):addSkills { "zhenlue", "ty__jianshu", "ty__yongdi" }
Fk:loadTranslationTable{
  ["ty__jiaxu"] = "贾诩",
  ["#ty__jiaxu"] = "料事如神",
  ["illustrator:ty__jiaxu"] = "凝聚永恒",

  ["~ty__jiaxu"] = "算无遗策，然终有疏漏……",
}

General:new(extension, "ty__chendeng", "qun", 3):addSkills { "wangzu", "yingshui", "fuyuan" }
Fk:loadTranslationTable{
  ["ty__chendeng"] = "陈登",
  ["#ty__chendeng"] = "湖海之士",
  ["illustrator:ty__chendeng"] = "游漫美绘",

  ["~ty__chendeng"] = "吾疾无人可治。",
}

General:new(extension, "caimaozhangyun", "wei", 4):addSkills { "lianzhou", "jinglan" }
Fk:loadTranslationTable{
  ["caimaozhangyun"] = "蔡瑁张允",
  ["#caimaozhangyun"] = "乘雷潜狡",
  ["designer:caimaozhangyun"] = "七哀",
  ["illustrator:caimaozhangyun"] = "君桓文化",

  ["~caimaozhangyun"] = "丞相，冤枉，冤枉啊！",
}

General:new(extension, "ty__gaolan", "qun", 4):addSkills { "xizhen" }
Fk:loadTranslationTable{
  ["ty__gaolan"] = "高览",
  ["#ty__gaolan"] = "诽殇之柱",
  ["designer:ty__gaolan"] = "七哀",
  ["illustrator:ty__gaolan"] = "君桓文化",

  ["~ty__gaolan"] = "郭公则害我！",
}

General:new(extension, "yinfuren", "wei", 3, 3, General.Female):addSkills { "yingyu", "yongbi" }
Fk:loadTranslationTable{
  ["yinfuren"] = "尹夫人",
  ["#yinfuren"] = "委身允翕",
  ["illustrator:yinfuren"] = "凝聚永恒",

  ["~yinfuren"] = "奈何遇君何其晚乎？",
}

General:new(extension, "ty__lvkuanglvxiang", "wei", 4):addSkills { "shuhe", "ty__liehou" }
Fk:loadTranslationTable{
  ["ty__lvkuanglvxiang"] = "吕旷吕翔",
  ["#ty__lvkuanglvxiang"] = "数合斩将",
  ["illustrator:ty__lvkuanglvxiang"] = "君桓文化",

  ["~ty__lvkuanglvxiang"] = "不避其死，以成其忠……",
}

General:new(extension, "chengui", "qun", 3):addSkills { "yingtu", "congshi" }
Fk:loadTranslationTable{
  ["chengui"] = "陈珪",
  ["#chengui"] = "弄虎如婴",
  ["designer:chengui"] = "千幻",
  ["illustrator:chengui"] = "游漫美绘",

  ["~chengui"] = "终日戏虎，竟为虎所噬。",
}

General:new(extension, "chenjiao", "wei", 3):addSkills { "xieshou", "qingyan", "qizi" }
Fk:loadTranslationTable{
  ["chenjiao"] = "陈矫",
  ["#chenjiao"] = "刚断骨鲠",
  ["designer:chenjiao"] = "朔方的雪",
  ["illustrator:chenjiao"] = "青岛君桓",

  ["~chenjiao"] = "矫既死，则魏再无直臣哉……",
}

General:new(extension, "qinlang", "wei", 4):addSkills { "haochong", "jinjin" }
Fk:loadTranslationTable{
  ["qinlang"] = "秦朗",
  ["#qinlang"] = "跼高蹐厚",
  ["designer:qinlang"] = "追风少年",
  ["illustrator:qinlang"] = "匠人绘",

  ["~qinlang"] = "二姓之人，死无其所……",
}

General:new(extension, "ty__dongzhao", "wei", 3):addSkills { "yijia", "dingji" }
Fk:loadTranslationTable{
  ["ty__dongzhao"] = "董昭",
  ["#ty__dongzhao"] = "筹定魏勋",
  ["designer:ty__dongzhao"] = "对勾对勾w",

  ["~ty__dongzhao"] = "凡有天下者，无虚伪不真之人……",
}

General:new(extension, "houcheng", "qun", 5):addSkills { "xianniang" }
Fk:loadTranslationTable{
  ["houcheng"] = "侯成",
  ["#houcheng"] = "猢威挽骊",
  ["illustrator:houcheng"] = "鬼画府",

  ["~houcheng"] = "将军，你不喝酒呀？",
}

local tangzi = General:new(extension, "ty__tangzi", "wei", 4)
tangzi.subkingdom = "wu"
tangzi:addSkills { "ty__xingzhao" }
tangzi:addRelatedSkill("xunxun")
Fk:loadTranslationTable{
  ["ty__tangzi"] = "唐咨",
  ["#ty__tangzi"] = "工学之奇才",
  ["designer:ty__tangzi"] = "荼蘼",
  ["illustrator:ty__tangzi"] = "六道目",

  ["$xunxun_ty__tangzi1"] = "兵者凶器也，将者儒夫也，文可掌兵。",
  ["$xunxun_ty__tangzi2"] = "良禽择木而栖，亦如君子不居于危墙。",
  ["~ty__tangzi"] = "水载船，亦可覆……",
}

General:new(extension, "ty__zangba", "wei", 4):addSkills { "ty__hengjiang" }
Fk:loadTranslationTable{
  ["ty__zangba"] = "臧霸",
  ["#ty__zangba"] = "节度青徐",
  ["illustrator:ty__zangba"] = "君桓文化",

  ["~ty__zangba"] = "断刃沉江，负主重托……",
}

General:new(extension, "ty__yuejin", "wei", 4):addSkills { "ty__xiaoguo" }
Fk:loadTranslationTable{
  ["ty__yuejin"] = "乐进",
  ["#ty__yuejin"] = "奋强突固",
  ["illustrator:ty__yuejin"] = "君桓文化",
  ["designer:ty__yuejin"] = "淬毒",

  ["~ty__yuejin"] = "箭疮发作，吾命休矣。",
}

--绕庭之鸦：黄皓√ 孙资刘放√ 岑昏√ 孙綝√ 贾充√
General:new(extension, "ty__huanghao", "shu", 3):addSkills { "ty__qinqing", "huisheng", "cunwei" }
Fk:loadTranslationTable{
  ["ty__huanghao"] = "黄皓",
  ["#ty__huanghao"] = "便辟佞慧",
  ["cv:ty__huanghao"] = "虞晓旭",
  ["illustrator:ty__huanghao"] = "游漫美绘",

  ["$huisheng_ty__huanghao1"] = "不就是想要好处嘛？",
  ["$huisheng_ty__huanghao2"] = "这些都拿去。",
  ["~ty__huanghao"] = "难道都是我一个人的错吗！",
}

General:new(extension, "ty__sunziliufang", "wei", 3):addSkills { "qinshen", "weidang" }
Fk:loadTranslationTable{
  ["ty__sunziliufang"] = "孙资刘放",
  ["#ty__sunziliufang"] = "谄陷负讥",
  ["designer:ty__sunziliufang"] = "七哀",
  ["illustrator:ty__sunziliufang"] = "君桓文化",

  ["~ty__sunziliufang"] = "臣一心为国朝，冤枉呀……",
}

General:new(extension, "ty__cenhun", "wu", 4):addSkills { "jishe", "lianhuo" }
Fk:loadTranslationTable{
  ["ty__cenhun"] = "岑昏",
  ["#ty__cenhun"] = "伐梁倾瓴",
  ["illustrator:ty__cenhun"] = "游漫美绘",
}

General:new(extension, "sunchen", "wu", 4):addSkills { "zigu", "zuowei" }
Fk:loadTranslationTable{
  ["sunchen"] = "孙綝",
  ["#sunchen"] = "凶竖盈溢",
  ["illustrator:sunchen"] = "君桓文化",
  ["designer:sunchen"] = "朔方的雪",

  ["~sunchen"] = "臣家火起，请离席救之……",
}

local jiachong = General:new(extension, "ty__jiachong", "wei", 3)
jiachong.subkingdom = "jin"
jiachong:addSkills { "ty__beini", "shizong" }
Fk:loadTranslationTable{
  ["ty__jiachong"] = "贾充",
  ["#ty__jiachong"] = "始作俑者",
  ["designer:ty__jiachong"] = "拔都沙皇",
  ["illustrator:ty__jiachong"] = "鬼画府",

  ["~ty__jiachong"] = "诸公勿怪，充乃奉命行事……",
}

--代汉涂高：马日磾√ 张勋√ 纪灵√ 雷薄√ 乐就√ 桥蕤√ 董绾√ 袁胤√
General:new(extension, "ty__mamidi", "qun", 4, 6):addSkills { "bingjie", "zhengding" }
Fk:loadTranslationTable{
  ["ty__mamidi"] = "马日磾",
  ["#ty__mamidi"] = "南冠楚囚",
  ["illustrator:ty__mamidi"] = "MUMU",

  ["~ty__mamidi"] = "失节屈辱忧恚！",
}

General:new(extension, "zhangxun", "qun", 4):addSkills { "suizheng" }
Fk:loadTranslationTable{
  ["zhangxun"] = "张勋",
  ["#zhangxun"] = "仲家将军",
  ["illustrator:zhangxun"] = "黑羽",

  ["~zhangxun"] = "此役，死伤甚重……",
}

General:new(extension, "ty__jiling", "qun", 4):addSkills { "ty__shuangren" }
Fk:loadTranslationTable{
  ["ty__jiling"] = "纪灵",
  ["#ty__jiling"] = "仲家的主将",
  ["illustrator:ty__jiling"] = "匠人绘",

  ["~ty__jiling"] = "穷寇兵枪势猛，伏义实在不敌啊。",
}

General:new(extension, "leibo", "qun", 4):addSkills { "silue", "shuaijie" }
Fk:loadTranslationTable{
  ["leibo"] = "雷薄",
  ["#leibo"] = "背仲豺寇",
  ["illustrator:leibo"] = "匠人绘",
  ["cv:leibo"] = "杨淼",

  ["~leibo"] = "此人不可力敌，速退！",
}

General:new(extension, "ty__yuejiu", "qun", 4):addSkills { "ty__cuijin" }
Fk:loadTranslationTable{
  ["ty__yuejiu"] = "乐就",
  ["#ty__yuejiu"] = "仲家军督",
  ["illustrator:ty__yuejiu"] = "匠人绘",

  ["~ty__yuejiu"] = "此役既败，请速斩我……",
}

General:new(extension, "ty__qiaorui", "qun", 4):addSkills { "aishou", "saowei" }
Fk:loadTranslationTable{
  ["ty__qiaorui"] = "桥蕤",
  ["#ty__qiaorui"] = "跛夫猎虎",
  ["designer:ty__qiaorui"] = "韩旭",
  ["illustrator:ty__qiaorui"] = "匠人绘",

  ["~ty__qiaorui"] = "今兵败城破，唯死而已。",
}

General:new(extension, "dongwan", "qun", 3, 3, General.Female):addSkills { "shengdu", "jieling" }
Fk:loadTranslationTable{
  ["dongwan"] = "董绾",
  ["#dongwan"] = "蜜言如鸩",
  ["designer:dongwan"] = "韩旭",
  ["illustrator:dongwan"] = "游漫美绘",

  ["~dongwan"] = "陛下饶命，妾并无歹意……",
}

General:new(extension, "yuanyin", "qun", 3):addSkills { "moshou", "yunjiu" }
Fk:loadTranslationTable{
  ["yuanyin"] = "袁胤",
  ["#yuanyin"] = "载路素车",
  ["illustrator:yuanyin"] = "错落宇宙",
  ["designer:yuanyin"] = "韩旭",

  ["~yuanyin"] = "臣不负忠，虽死如是……",
}

--江湖之远：管宁√ 黄承彦 胡昭√ 王烈 孟节
General:new(extension, "guanning", "qun", 3, 7):addSkills { "dunshi" }
Fk:loadTranslationTable{
  ["guanning"] = "管宁",
  ["#guanning"] = "辟境归元",
  ["designer:guanning"] = "七哀",
  ["illustrator:guanning"] = "游漫美绘",

  ["~guanning"] = "高节始终，无憾矣。",
}

--local huangchengyan = General:new(extension, "ty__huangchengyan", "qun", 3)
--huangchengyan:addSkills { "jiezhen", "zecai", "yinshih" }
--huangchengyan:addRelatedSkill("bazhen")
Fk:loadTranslationTable{
  ["ty__huangchengyan"] = "黄承彦",
  ["#ty__huangchengyan"] = "捧月共明",
  ["designer:ty__huangchengyan"] = "七哀",
  ["illustrator:ty__huangchengyan"] = "凡果",

  ["~ty__huangchengyan"] = "卧龙出山天伦逝，悔教吾婿离南阳……",
}

local huzhao = General:new(extension, "huzhao", "qun", 3)
huzhao:addSkills { "midu", "xianwang" }
huzhao:addRelatedSkill("ty_ex__huomo")
Fk:loadTranslationTable{
  ["huzhao"] = "胡昭",
  ["#huzhao"] = "阖门守静",
  ["illustrator:huzhao"] = "游漫美绘",
  ["designer:huzhao"] = "神壕",

  ["$ty_ex__huomo_huzhao1"] = "行文挥毫，得心应手。",
  ["$ty_ex__huomo_huzhao2"] = "泼墨走笔，挥洒自如。",
  ["~huzhao"] = "纵有清名，无益于世也。",
}

--General:new(extension, "wanglie", "qun", 3):addSkills { "chongwang", "huagui" }
Fk:loadTranslationTable{
  ["wanglie"] = "王烈",
  ["#wanglie"] = "通识达道",
  ["designer:wanglie"] = "七哀",
  ["cv:wanglie"] = "虞晓旭",
  ["illustrator:wanglie"] = "青岛君桓",

  ["~wanglie"] = "烈尚不能自断，何断人乎？",
}

--General:new(extension, "mengjie", "qun", 3):addSkills { "yinlu", "youqi" }
Fk:loadTranslationTable{
  ["mengjie"] = "孟节",
  ["#mengjie"] = "万安隐者",
  ["designer:mengjie"] = "神壕",
  ["illustrator:mengjie"] = "君桓文化",

  ["~mengjie"] = "蛮人无知，请丞相教之……",
}

--悬壶济世：吉平 孙寒华 郑浑 刘宠骆俊 吴普
--纵横捭阖：陆郁生 祢衡 华歆 荀谌 冯熙 邓芝 宗预 羊祜
--匡鼎炎汉：刘巴 杨仪 黄权 吴班 霍峻 傅肜傅佥 向朗 高翔 李丰 张翼 蒋琬费祎
--太平甲子：管亥√ 张闿√ 刘辟√ 裴元绍√ 张楚√ 张曼成√
General:new(extension, "guanhai", "qun", 4):addSkills { "suoliang", "qinbao" }
Fk:loadTranslationTable{
  ["guanhai"] = "管亥",
  ["#guanhai"] = "掠地劫州",
  ["illustrator:guanhai"] = "六道目",

  ["~guanhai"] = "这红脸汉子，为何如此眼熟……",
}

General:new(extension, "zhangkai", "qun", 4):addSkills { "xiangshuz" }
Fk:loadTranslationTable{
  ["zhangkai"] = "张闿",
  ["#zhangkai"] = "无餍狍鸮",
  ["illustrator:zhangkai"] = "猎枭",

  ["~zhangkai"] = "报应竟来得这么快……",
}

General:new(extension, "liupi", "qun", 4):addSkills { "juying" }
Fk:loadTranslationTable{
  ["liupi"] = "刘辟",
  ["#liupi"] = "慕义渠帅",
  ["designer:liupi"] = "韩旭",
  ["illustrator:liupi"] = "君桓文化",

  ["~liupi"] = "玄德公高义，辟宁死不悔！",
}

General:new(extension, "peiyuanshao", "qun", 4):addSkills { "moyu" }
Fk:loadTranslationTable{
  ["peiyuanshao"] = "裴元绍",
  ["#peiyuanshao"] = "买椟还珠",
  ["designer:peiyuanshao"] = "步穗",
  ["illustrator:peiyuanshao"] = "匠人绘",

  ["~peiyuanshao"] = "好生厉害的白袍小将……",
}

General:new(extension, "zhangchu", "qun", 3, 3, General.Female):addSkills { "jizhong", "rihui", "guangshi" }
Fk:loadTranslationTable{
  ["zhangchu"] = "张楚",
  ["#zhangchu"] = "大贤后裔",
  ["cv:zhangchu"] = "千欢欢",
  ["designer:zhangchu"] = "韩旭",
  ["illustrator:zhangchu"] = "黯荧岛工作室",

  ["~zhangchu"] = "苦难不尽，黄天不死……",
}

General:new(extension, "ty__zhangmancheng", "qun", 4):addSkills { "luecheng", "zhongji" }
Fk:loadTranslationTable{
  ["ty__zhangmancheng"] = "张曼成",
  ["#ty__zhangmancheng"] = "蚁萃宛洛",
  ["designer:ty__zhangmancheng"] = "快雪时晴",
  ["illustrator:ty__zhangmancheng"] = "君桓文化",

  ["~ty__zhangmancheng"] = "逡巡不前，坐以待毙……",
}

--异军突起：公孙度√ 孟优√ SP孟获√ 公孙修√ 马腾√
General:new(extension, "gongsundu", "qun", 4):addSkills { "zhenze", "anliao" }
Fk:loadTranslationTable{
  ["gongsundu"] = "公孙度",
  ["#gongsundu"] = "雄张海东",
  ["designer:gongsundu"] = "拔都沙皇",
  ["illustrator:gongsundu"] = "匠人绘",

  ["~gongsundu"] = "为何都不愿出仕！",
}

General:new(extension, "mengyou", "qun", 5):addSkills { "manyi", "manzhi" }
Fk:loadTranslationTable{
  ["mengyou"] = "孟优",
  ["#mengyou"] = "蛮杰陷谋",
  ["designer:mengyou"] = "残昼厄夜",
  ["illustrator:mengyou"] = "韩少侠&错落宇宙",

  ["$manyi_mengyou1"] = "我辈蛮夷久居荒野，岂为兽虫所伤。",
  ["$manyi_mengyou2"] = "我乃蛮王孟获之弟，谁敢伤我！",
  ["~mengyou"] = "大哥，诸葛亮又打来了。",
}

local menghuo = General:new(extension, "ty_sp__menghuo", "qun", 4)
menghuo:addSkills { "ty__manwang" }
menghuo:addRelatedSkill("ty__panqin")
Fk:loadTranslationTable{
  ["ty_sp__menghuo"] = "孟获",
  ["#ty_sp__menghuo"] = "勒格诗惹",
  ["designer:ty_sp__menghuo"] = "玄蝶既白",
  ["illustrator:ty_sp__menghuo"] = "凡果",

  ["~ty_sp__menghuo"] = "有材而得生，无材而得纵……",
}

General:new(extension, "gongsunxiu", "qun", 4):addSkills { "gangu", "kuizhen" }
Fk:loadTranslationTable{
  ["gongsunxiu"] = "公孙修",
  ["#gongsunxiu"] = "寸莛击钟",
  ["cv:gongsunxiu"] = "李陌上同学",
  ["designer:gongsunxiu"] = "龘老师",
  ["illustrator:gongsunxiu"] = "鬼画府",

  ["~gongsunxiu"] = "大星坠地，父子俱亡……",
}

General:new(extension, "ty__mateng", "qun", 4):addSkills { "mashu", "ty__xiongyi" }
Fk:loadTranslationTable{
  ["ty__mateng"] = "马腾",
  ["#ty__mateng"] = "驰骋西陲",
  ["illustrator:ty__mateng"] = "君桓文化",

  ["~ty__mateng"] = "儿子，为爹报仇啊！",
}

--正音雅乐：蔡文姬√ 周妃√ 祢衡√ 大乔√ 小乔√ 邹氏√ 貂蝉√ 周瑜√
General:new(extension, "mu__caiwenji", "qun", 3, 3, General.Female):addSkills { "shuangjia", "beifen" }
Fk:loadTranslationTable{
  ["mu__caiwenji"] = "乐蔡文姬",
  ["#mu__caiwenji"] = "胡笳十八拍",
  ["designer:mu__caiwenji"] = "星移",
  ["illustrator:mu__caiwenji"] = "匠人绘",

  ["~mu__caiwenji"] = "天何薄我，天何薄我……",
}

General:new(extension, "mu__zhoufei", "wu", 3, 3, General.Female):addSkills { "lingkong", "xianshu" }
Fk:loadTranslationTable{
  ["mu__zhoufei"] = "乐周妃",
  ["#mu__zhoufei"] = "芙蓉泣露",
  ["illustrator:mu__zhoufei"] = "匠人绘",

  ["~mu__zhoufei"] = "红颜薄命，望君珍重……",
}

General:new(extension, "mu__miheng", "qun", 3):addSkills { "jigu", "sirui" }
Fk:loadTranslationTable{
  ["mu__miheng"] = "乐祢衡",
  ["#mu__miheng"] = "鹗立鸷群",
  ["designer:mu__miheng"] = "星移",
  ["illustrator:mu__miheng"] = "君桓文化",
  ["cv:mu__miheng"] = "虞晓旭",

  ["~mu__miheng"] = "映日荷花今尤在，不见当年采荷人……",
}

General:new(extension, "mu__daqiao", "wu", 3, 3, General.Female):addSkills { "qiqin", "zixi" }
Fk:loadTranslationTable{
  ["mu__daqiao"] = "乐大乔",
  ["#mu__daqiao"] = "玉桐姊韵",
  ["illustrator:mu__daqiao"] = "匠人绘",
  ["designer:mu__daqiao"] = "星移",

  ["$qiqin_mu__daqiao1"] = "山月栖瑶琴，一曲渔歌和晚音。",
  ["$qiqin_mu__daqiao2"] = "指尖有琴音，何不于君指上听？",
  ["~mu__daqiao"] = "曲终人散，再会奈何桥畔……",
}
local zixi = fk.CreateCard{
  name = "&zixi_trick",
  type = Card.TypeTrick,
  sub_type = Card.SubtypeDelayedTrick,
}
extension:loadCardSkels{zixi}
extension:addCardSpec("zixi_trick")

General:new(extension, "mu__xiaoqiao", "wu", 3, 3, General.Female):addSkills { "qiqin", "weiwan" }
Fk:loadTranslationTable{
  ["mu__xiaoqiao"] = "乐小乔",
  ["#mu__xiaoqiao"] = "绿绮嫒媛",
  ["illustrator:mu__xiaoqiao"] = "匠人绘",
  ["designer:mu__xiaoqiao"] = "星移",

  ["$qiqin_mu__xiaoqiao1"] = "渔歌唱晚落山月，素琴薄暮声。",
  ["$qiqin_mu__xiaoqiao2"] = "指上琴音浅，欲听还需抚瑶琴。",
  ["~mu__xiaoqiao"] = "独寄人间白首，曲误周郎难顾……",
}

General:new(extension, "mu__zoushi", "qun", 3, 3, General.Female):addSkills { "yunzheng", "mu__huoxin" }
Fk:loadTranslationTable{
  ["mu__zoushi"] = "乐邹氏",
  ["#mu__zoushi"] = "淯水吟",
  ["designer:mu__zoushi"] = "星移",
  ["cv:mu__zoushi"] = "楼倾司",
  ["illustrator:mu__zoushi"] = "黯荧岛",

  ["~mu__zoushi"] = "雁归衡阳，良人当还……",
}

General:new(extension, "mu__diaochan", "qun", 3, 3, General.Female):addSkills { "tanban", "diou" }
Fk:loadTranslationTable{
  ["mu__diaochan"] = "乐貂蝉",
  ["#mu__diaochan"] = "檀声向晚",
  ["designer:mu__diaochan"] = "星移",
  ["illustrator:mu__diaochan"] = "鬼画府",

  ["~mu__diaochan"] = "红颜薄命，一曲离歌终……",
}

General:new(extension, "mu__zhouyu", "wu", 3):addSkills { "guyinz", "pinglu" }
Fk:loadTranslationTable{
  ["mu__zhouyu"] = "乐周瑜",
  ["#mu__zhouyu"] = "顾曲周郎",
  ["illustrator:mu__zhouyu"] = "觉觉",

  ["~mu__zhouyu"] = "高山难觅流水意，曲终人散皆难违。",
}

--百战虎贲：兀突骨√ 文鸯√ 夏侯霸√ 皇甫嵩√ 王双√ 留赞√ 雷铜√ 吴兰√ 黄祖√ 陈泰√ 王濬√ 杜预√ 文钦√ 胡遵√ 蒋钦√ 张任√ 凌操√ 吕据√ 陈武董袭 丁奉x
General:new(extension, "ty__wutugu", "qun", 15):addSkills { "ty__ranshang", "ty__hanyong" }
Fk:loadTranslationTable{
  ["ty__wutugu"] = "兀突骨",
  ["#ty__wutugu"] = "霸体金刚",
  ["illustrator:ty__wutugu"] = "梦回唐朝",

  ["~ty__wutugu"] = "不可能！这不可能！",
}

local wenyang = General:new(extension, "wenyang", "wei", 5)
wenyang:addSkills { "lvli", "choujue" }
wenyang:addRelatedSkills { "beishui", "qingjiao" }
Fk:loadTranslationTable{
  ["wenyang"] = "文鸯",
  ["#wenyang"] = "万将披靡",
  ["designer:wenyang"] = "韩旭",
  ["illustrator:wenyang"] = "Thinking",

  ["~wenyang"] = "痛贯心膂，天灭大魏啊！",
}

local xiahouba = General:new(extension, "ty__xiahouba", "shu", 4)
xiahouba:addSkills { "ty__baobian" }
xiahouba:addRelatedSkills { "tiaoxin", "ex__paoxiao", "ol_ex__shensu" }
Fk:loadTranslationTable{
  ["ty__xiahouba"] = "夏侯霸",
  ["#ty__xiahouba"] = "棘途壮志",
  ["illustrator:ty__xiahouba"] = "秋呆呆",

  ["$tiaoxin_ty__xiahouba1"] = "本将军不与无名之辈相战！",
  ["$tiaoxin_ty__xiahouba2"] = "尔等无名小辈，怎入本将军法眼？",
  ["$ex__paoxiao_ty__xiahouba1"] = "吾岂容尔等小觑？",
  ["$ex__paoxiao_ty__xiahouba2"] = "杀，杀他个片甲不留！",
  ["$ol_ex__shensu_ty__xiahouba1"] = "兵贵神速，机不可失！",
  ["$ol_ex__shensu_ty__xiahouba2"] = "兵之情主速！",
  ["~ty__xiahouba"] = "明敌易防，暗箭难躲……",
}

General:new(extension, "ty__huangfusong", "qun", 4):addSkills { "ty__fenyue" }
Fk:loadTranslationTable{
  ["ty__huangfusong"] = "皇甫嵩",
  ["#ty__huangfusong"] = "志定雪霜",
  ["illustrator:ty__huangfusong"] = "秋呆呆",

  ["~ty__huangfusong"] = "吾只恨黄巾未平，不能报效朝廷……",
}

General:new(extension, "wangshuang", "wei", 8):addSkills { "zhuilie" }
Fk:loadTranslationTable{
  ["wangshuang"] = "王双",
  ["#wangshuang"] = "遏北的悍锋",
  ["illustrator:wangshuang"] = "biou09",

  ["~wangshuang"] = "我居然，被蜀军所击倒。",
}

General:new(extension, "ty__liuzan", "wu", 4):addSkills { "ty__fenyin", "liji" }
Fk:loadTranslationTable{
  ["ty__liuzan"] = "留赞",
  ["#ty__liuzan"] = "啸天亢声",
  ["illustrator:ty__liuzan"] = "酸包",

  ["~ty__liuzan"] = "若因病困此，命矣。",
}

General:new(extension, "leitong", "shu", 4):addSkills { "kuiji" }
Fk:loadTranslationTable{
  ["leitong"] = "雷铜",
  ["#leitong"] = "石铠之鼋",
  ["designer:leitong"] = "梦魇狂朝",
  ["illustrator:leitong"] = "M云涯",

  ["~leitong"] = "翼德救我……",
}

General:new(extension, "wulan", "shu", 4):addSkills { "cuoruiw" }
Fk:loadTranslationTable{
  ["wulan"] = "吴兰",
  ["#wulan"] = "剑齿之鼍",
  ["designer:wulan"] = "梦魇狂朝",
  ["illustrator:wulan"] = "alien",

  ["~wulan"] = "蛮狗，尔敢杀我！",
}

General:new(extension, "ty__huangzu", "qun", 4):addSkills { "jinggong", "xiaojun" }
Fk:loadTranslationTable{
  ["ty__huangzu"] = "黄祖",
  ["#ty__huangzu"] = "引江为弣",
  ["illustrator:ty__huangzu"] = "福州明暗",

  ["~ty__huangzu"] = "周瑜小儿，竟破了我的埋伏？",
}

General:new(extension, "chentai", "wei", 4):addSkills { "jiuxianc", "chenyong" }
Fk:loadTranslationTable{
  ["chentai"] = "陈泰",
  ["#chentai"] = "岳峙渊渟",
  ["designer:chentai"] = "朔方的雪",
  ["illustrator:chentai"] = "画画的闻玉",

  ["~chentai"] = "公非旦，我非勃……",
}

local wangjun = General:new(extension, "ty__wangjun", "qun", 4)
wangjun.subkingdom = "jin"
wangjun:addSkills { "tongye", "changqu" }
Fk:loadTranslationTable{
  ["ty__wangjun"] = "王濬",
  ["#ty__wangjun"] = "遏浪飞艨",
  ["illustrator:ty__wangjun"] = "错落宇宙",

  ["~ty__wangjun"] = "未蹈曹刘覆辙，险遭士载之厄……",
}

local duyu = General:new(extension, "ty__duyu", "wei", 4)
duyu.subkingdom = "jin"
duyu:addSkills { "jianguo", "qingshid" }
Fk:loadTranslationTable{
  ["ty__duyu"] = "杜预",
  ["#ty__duyu"] = "文成武德",
  ["designer:ty__duyu"] = "坑坑",
  ["illustrator:ty__duyu"] = "君桓文化",

  ["~ty__duyu"] = "六合即归一统，奈何寿数已尽……",
}

local wenqin = General:new(extension, "ty__wenqin", "wei", 4)
wenqin.subkingdom = "wu"
wenqin:addSkills { "guangao", "ty__huiqi" }
wenqin:addRelatedSkill("ty__xieju")
Fk:loadTranslationTable{
  ["ty__wenqin"] = "文钦",
  ["#ty__wenqin"] = "困兽鸱张",
  ["illustrator:ty__wenqin"] = "极智",

  ["$guangao_ty__wenqin1"] = "群士言虚而无功，非吾在麾之宾。",
  ["$guangao_ty__wenqin2"] = "吾欲捕虏擒俘，以邀策勋之赏。",
  ["~ty__wenqin"] = "世受国恩，安能坐视权奸为患……",
}

General:new(extension, "huzun", "wei", 4):addSkills { "zhantao", "anjing" }
Fk:loadTranslationTable{
  ["huzun"] = "胡遵",
  ["#huzun"] = "蓝翎紫璧",
  ["illustrator:huzun"] = "君桓文化",

  ["~huzun"] = "耻败于诸葛小儿之手……",
}

General:new(extension, "ty__jiangqin", "wu", 4):addSkills { "ty__shangyi", "ty__niaoxiang" }
Fk:loadTranslationTable{
  ["ty__jiangqin"] = "蒋钦",
  ["#ty__jiangqin"] = "祁奚之器",
  ["illustrator:ty__jiangqin"] = "君桓文化",

  ["~ty__jiangqin"] = "竟破我阵法……",
}

General:new(extension, "ty__zhangren", "qun", 4):addSkills { "ty__chuanxin", "ty__fengshi" }
Fk:loadTranslationTable{
  ["ty__zhangren"] = "张任",
  ["#ty__zhangren"] = "索命神射",
  ["illustrator:ty__zhangren"] = "君桓文化",

  ["~ty__zhangren"] = "本将军败于诸葛，无憾……",
}

General:new(extension, "ty__lingcao", "wu", 4, 5):addSkills { "dufeng" }
Fk:loadTranslationTable{
  ["ty__lingcao"] = "凌操",
  ["#ty__lingcao"] = "激浪奋孤胆",
  ["illustrator:ty__lingcao"] = "黯荧岛",

  ["~ty__lingcao"] = "甘宁小儿，为何暗箭伤人！",
}

General:new(extension, "lvju", "wu", 4):addSkills { "zhengyue" }
Fk:loadTranslationTable{
  ["lvju"] = "吕据",
  ["#lvju"] = "仗钺征镇",
  ["designer:lvju"] = "银蛋",
  ["illustrator:lvju"] = "君桓文化",

  ["~lvju"] = "孙綝，你不当人子！",
}

--奇人异士：张宝 司马徽 蒲元 管辂 葛玄 杜夔 朱建平 吴范 赵直 周宣 笮融
General:new(extension, "guanlu", "wei", 3):addSkills { "tuiyan", "busuan", "mingjie" }
Fk:loadTranslationTable{
  ["guanlu"] = "管辂",
  ["#guanlu"] = "问天通神",
  ["illustrator:guanlu"] = "alien",

  ["~guanlu"] = "怀我好英，心非草木……",
}

--计将安出：程昱 王允 蒋干 刘琦 赵昂 刘晔 杨弘 桓范 郤正 田丰 吕范
--豆蔻梢头：诸葛果√ 花鬘 辛宪英 薛灵芸 芮姬 段巧笑 田尚衣 柏灵筠 马伶俐 莫琼树√ 曹媛√ 灵雎√
General:new(extension, "ty__zhugeguo", "shu", 3, 3, General.Female):addSkills { "ty__qirang", "ty__yuhua" }
Fk:loadTranslationTable{
  ["ty__zhugeguo"] = "诸葛果",
  ["#ty__zhugeguo"] = "祈福安宁",
  ["illustrator:ty__zhugeguo"] = "Thinking&alien",

  ["~ty__zhugeguo"] = "镜中花，水中月，往事如烟。",
}

General:new(extension, "moqiongshu", "wei", 3, 3, General.Female):addSkills { "wanchan", "jiangzhi" }
Fk:loadTranslationTable{
  ["moqiongshu"] = "莫琼树",
  ["#moqiongshu"] = "琼黛鬓墨雪",
  ["illustrator:moqiongshu"] = "黯荧岛",
  ["designer:moqiongshu"] = "韩旭",

  ["~moqiongshu"] = "昔日桃花面，今朝已泛黄……",
}

General:new(extension, "caoyuan", "qun", 3, 3, General.Female):addSkills { "wuyanc", "zhanyu" }
Fk:loadTranslationTable{
  ["caoyuan"] = "曹媛",
  ["#caoyuan"] = "千娇百媚",
  ["illustrator:caoyuan"] = "花狐貂",

  ["~caoyuan"] = "若寻到了那楚霸王，谁不甘心做虞姬？",
}

General:new(extension, "ty__lingju", "qun", 3, 3, General.Female):addSkills { "ty__jieyuan", "ty__fenxin" }
Fk:loadTranslationTable{
  ["ty__lingju"] = "灵雎",
  ["#ty__lingju"] = "情随梦逝",
  ["illustrator:ty__lingju"] = "路人z",

  ["~ty__lingju"] = "世有万般苦难，奈何于我一身？",
}

--皇家贵胄：孙皓√ 士燮√ 曹髦 刘辩√ 刘虞√ 全惠解 丁尚涴 袁姬√ 谢灵毓 孙瑜 甘夫人糜夫人√ 清河公主√ 曹芳√ 朱佩兰√ 卞玥√
--徐馨√ 孙霸√ 甘夫人√ 糜夫人√ 卞夫人x
General:new(extension, "ty__sunhao", "wu", 5):addSkills { "canshi", "ty__chouhai", "guiming" }
Fk:loadTranslationTable{
  ["ty__sunhao"] = "孙皓",
  ["#ty__sunhao"] = "时日曷丧",
  ["designer:ty__sunhao"] = "韩旭",
  ["illustrator:ty__sunhao"] = "君桓文化",

  ["$canshi_ty__sunhao1"] = "天地不仁，当视苍生为刍狗！",
  ["$canshi_ty__sunhao2"] = "真龙天子，焉能不择人而噬！",
  ["$guiming_ty__sunhao1"] = "朕奉天承运，谁敢不从！",
  ["$guiming_ty__sunhao2"] = "朕一日为吴皇，则终生为吴皇！",
  ["~ty__sunhao"] = "八十万人齐卸甲，一片降幡出石头。",
}

General:new(extension, "ty__shixie", "qun", 3):addSkills { "ty__biluan", "ty__lixia" }
Fk:loadTranslationTable{
  ["ty__shixie"] = "士燮",
  ["#ty__shixie"] = "雄长百越",
  ["illustrator:ty__shixie"] = "陈龙",

  ["~ty__shixie"] = "老夫此生，了无遗憾。",
}

--General:new(extension, "caomao", "wei", 3, 4):addSkills { "qianlong", "fensi", "juetao", "zhushi" }
Fk:loadTranslationTable{
  ["caomao"] = "曹髦",
  ["#caomao"] = "霸业的终耀",
  ["illustrator:caomao"] = "游漫美绘",

  ["~caomao"] = "宁作高贵乡公死，不作汉献帝生……",
}

General:new(extension, "liubian", "qun", 3):addSkills { "shiyuan", "dushi", "yuwei" }
Fk:loadTranslationTable{
  ["liubian"] = "刘辩",
  ["#liubian"] = "弘农怀王",
  ["designer:liubian"] = "韩旭",
  ["cv:liubian"] = "-安志-",
  ["illustrator:liubian"] = "zoo",

  ["~liubian"] = "侯非侯，王非王……",
}

local liuyu = General:new(extension, "ty__liuyu", "qun", 3)
liuyu:addSkills { "suifu", "pijing" }
liuyu:addRelatedSkill("zimu")
Fk:loadTranslationTable{
  ["ty__liuyu"] = "刘虞",
  ["#ty__liuyu"] = "维城燕北",
  ["designer:ty__liuyu"] = "七哀",
  ["illustrator:ty__liuyu"] = "君桓文化",

  ["~ty__liuyu"] = "公孙瓒谋逆，人人可诛！",
}




General:new(extension, "yuanji", "wu", 3, 3, General.Female):addSkills { "fangdu", "jiexing" }
Fk:loadTranslationTable{
  ["yuanji"] = "袁姬",
  ["#yuanji"] = "袁门贵女",
  ["designer:yuanji"] = "韩旭",
  ["illustrator:yuanji"] = "匠人绘",

  ["~yuanji"] = "妾本蒲柳，幸荣君恩……",
}

--General:new(extension, "xielingyu", "wu", 3, 3, General.Female):addSkills { "yuandi", "xinyou" }
Fk:loadTranslationTable{
  ["xielingyu"] = "谢灵毓",
  ["#xielingyu"] = "淑静才媛",
  ["designer:xielingyu"] = "韩旭",
  ["illustrator:xielingyu"] = "游漫美绘",

  ["~xielingyu"] = "翠瓦红墙处，最折意中人。",
}

--General:new(extension, "sunyu", "wu", 3):addSkills { "quanshou", "shexue" }
Fk:loadTranslationTable{
  ["sunyu"] = "孙瑜",
  ["#sunyu"] = "镇据边陲",
  ["designer:sunyu"] = "胜天半子ying",
  ["illustrator:sunyu"] = "CatJade玉猫",

  ["~sunyu"] = "孙氏始得江东，奈何魂归黄泉……",
}

General:new(extension, "ganfurenmifuren", "shu", 3, 3, General.Female):addSkills { "chanjuan", "xunbie" }
Fk:loadTranslationTable{
  ["ganfurenmifuren"] = "甘夫人糜夫人",
  ["#ganfurenmifuren"] = "千里婵娟",
  ["designer:ganfurenmifuren"] = "星移",
  ["illustrator:ganfurenmifuren"] = "七兜豆",

  ["~ganfurenmifuren"] = "人生百年，奈何于我十不存一……",
}

General:new(extension, "ty__qinghegongzhu", "wei", 3, 3, General.Female):addSkills { "ty__zhangjiq", "ty__zengou" }
Fk:loadTranslationTable{
  ["ty__qinghegongzhu"] = "清河公主",
  ["#ty__qinghegongzhu"] = "大魏长公主",
  ["illustrator:ty__qinghegongzhu"] = "七兜豆",
  ["designer:ty__qinghegongzhu"] = "星移",

  ["~ty__qinghegongzhu"] = "夏侯楙，不能和好，为何不和离？",
}

General:new(extension, "caofang", "wei", 4):addSkills { "zhimin", "jujianc" }
Fk:loadTranslationTable{
  ["caofang"] = "曹芳",
  ["#caofang"] = "迷瞑终觉",
  ["cv:caofang"] = "陆泊云",
  ["designer:caofang"] = "银蛋",
  ["illustrator:caofang"] = "鬼画府",

  ["~caofang"] = "匹夫无罪，怀璧其罪……",
}

General:new(extension, "zhupeilan", "wu", 3, 3, General.Female):addSkills { "cilv", "tongdao" }
Fk:loadTranslationTable{
  ["zhupeilan"] = "朱佩兰",
  ["#zhupeilan"] = "景皇后",
  ["designer:zhupeilan"] = "星移",
  ["illustrator:zhupeilan"] = "匠人绘",

  ["~zhupeilan"] = "生如浮萍，随波而逝……",
}

General:new(extension, "bianyue", "wei", 3, 3, General.Female):addSkills { "bizu", "wuxie" }
Fk:loadTranslationTable{
  ["bianyue"] = "卞玥",
  ["#bianyue"] = "暮辉映族",
  ["designer:bianyue"] = "银蛋",
  ["cv:bianyue"] = "关云云月",
  ["illustrator:bianyue"] = "黯荧岛",

  ["~bianyue"] = "空怀悲怆之心，未有杀贼之力……",
}

General:new(extension, "xuxin", "wu", 3, 3, General.Female):addSkills { "yuxian", "minshan" }
Fk:loadTranslationTable{
  ["xuxin"] = "徐馨",
  ["#xuxin"] = "望云思归",
  ["illustrator:xuxin"] = "鬼画府",

  ["~xuxin"] = "无情总是帝王家。",
}

General:new(extension, "sunba", "wu", 4):addSkills { "jiedang", "jidi" }
Fk:loadTranslationTable{
  ["sunba"] = "孙霸",
  ["#sunba"] = "庶怨嫡位",
  ["illustrator:sunba"] = "君桓文化",

  ["~sunba"] = "殿陛之争，非胜即死。",
}

General:new(extension, "ty__ganfuren", "shu", 3, 3, General.Female):addSkills { "ty__shushen", "ty__shenzhi" }
Fk:loadTranslationTable{
  ["ty__ganfuren"] = "甘夫人",
  ["#ty__ganfuren"] = "昭烈皇后",
  ["illustrator:ty__ganfuren"] = "胖虎饭票",

  ["~ty__ganfuren"] = "请替我照顾好阿斗……",
}

local mifuren = General:new(extension, "ty__mifuren", "shu", 3, 3, General.Female)
mifuren:addSkills { "ty__guixiu", "ty__cunsi" }
mifuren:addRelatedSkill("ty__yongjue")
Fk:loadTranslationTable{
  ["ty__mifuren"] = "糜夫人",
  ["#ty__mifuren"] = "乱世沉香",
  ["illustrator:ty__mifuren"] = "鲨鱼嚼嚼",

  ["~ty__mifuren"] = "阿斗被救，妾身……再无牵挂……",
}

--往者可谏：大乔小乔x SP马超√ SP赵云x SP甄姬√ SP孙策x
General:new(extension, "ty_sp__machao", "qun", 4):addSkills { "ty__zhuiji", "ty__shichou" }
Fk:loadTranslationTable{
  ["ty_sp__machao"] = "马超",
  ["#ty_sp__machao"] = "威震西凉",
  ["illustrator:ty_sp__machao"] = "匠人绘",

  ["~ty_sp__machao"] = "西凉众将离心，父仇难报",
}

General:new(extension, "ty_sp__zhenji", "qun", 3, 3, General.Female):addSkills { "jijiez", "huiji" }
Fk:loadTranslationTable{
  ["ty_sp__zhenji"] = "甄姬",
  ["#ty_sp__zhenji"] = "善言贤女",
  ["designer:ty_sp__zhenji"] = "星移",
  ["illustrator:ty_sp__zhenji"] = "匠人绘",

  ["~ty_sp__zhenji"] = "自古英雄迟暮，谁见佳人白头？",
}

--章台春望：郭照√ 樊玉凤√ 阮瑀√ 杨婉√ 潘淑√
General:new(extension, "guozhao", "wei", 3, 3, General.Female):addSkills { "pianchong", "zunwei" }
Fk:loadTranslationTable{
  ["guozhao"] = "郭照",
  ["#guozhao"] = "碧海青天",
  ["cv:guozhao"] = "楼倾司",
  ["designer:guozhao"] = "世外高v狼",
  ["illustrator:guozhao"] = "杨杨和夏季",

  ["~guozhao"] = "我的出身，不配为后？",
}

General:new(extension, "fanyufeng", "qun", 3, 3, General.Female):addSkills { "bazhan", "jiaoying" }
Fk:loadTranslationTable{
  ["fanyufeng"] = "樊玉凤",
  ["#fanyufeng"] = "红鸾寡宿",
  ["cv:fanyufeng"] = "杨子怡",
  ["illustrator:fanyufeng"] = "匠人绘",

  ["~fanyufeng"] = "醮妇再遇良人难……",
}

General:new(extension, "ruanyu", "wei", 3):addSkills { "xingzuo", "miaoxian" }
Fk:loadTranslationTable{
  ["ruanyu"] = "阮瑀",
  ["#ruanyu"] = "斐章雅律",
  ["designer:ruanyu"] = "步穗",
  ["illustrator:ruanyu"] = "alien",

  ["~ruanyu"] = "良时忽过，身为土灰。",
}

General:new(extension, "ty__yangwan", "shu", 3, 3, General.Female):addSkills { "youyan", "zhuihuan" }
Fk:loadTranslationTable{
  ["ty__yangwan"] = "杨婉",
  ["#ty__yangwan"] = "融沫之鲡",
  ["illustrator:ty__yangwan"] = "木美人",

  ["~ty__yangwan"] = "遇人不淑……",
}

General:new(extension, "ty__panshu", "wu", 3, 3, General.Female):addSkills { "zhiren", "yaner" }
Fk:loadTranslationTable{
  ["ty__panshu"] = "潘淑",
  ["#ty__panshu"] = "神女",
  ["designer:ty__panshu"] = "韩旭",
  ["illustrator:ty__panshu"] = "杨杨和夏季",

  ["~ty__panshu"] = "有喜必忧，以为深戒！",
}

--锦瑟良缘：曹金玉√ 孙翊√ 冯妤√ 来莺儿√ 曹华√ 张奋 诸葛若雪√ 诸葛梦雪√ 曹宪√ 柳婒√ 文鸳√
General:new(extension, "caojinyu", "wei", 3, 3, General.Female):addSkills { "yuqi", "shanshen", "xianjing" }
Fk:loadTranslationTable{
  ["caojinyu"] = "曹金玉",
  ["#caojinyu"] = "金乡公主",
  ["designer:caojinyu"] = "韩旭",
  ["illustrator:caojinyu"] = "MUMU",
  ["cv:caojinyu"] = "亦喵酱",

  ["~caojinyu"] = "平叔之情，吾岂不明。",
}

local sunyi = General:new(extension, "ty__sunyi", "wu", 5)
sunyi:addSkills { "jiqiaos", "xiongyis" }
sunyi:addRelatedSkills { "hunzi", "ex__yingzi", "yinghun" }
Fk:loadTranslationTable{
  ["ty__sunyi"] = "孙翊",
  ["#ty__sunyi"] = "虓风快意",
  ["designer:ty__sunyi"] = "七哀",
  ["illustrator:ty__sunyi"] = "君桓文化",

  ["$hunzi_ty__sunyi1"] = "身临绝境，亦当心怀壮志！",
  ["$hunzi_ty__sunyi2"] = "危难之时，自当振奋以对！",
  ["$ex__yingzi_ty__sunyi"] = "骁悍果烈，威震江东！",
  ["$yinghun_ty__sunyi"] = "兄弟齐心，以保父兄基业！",
  ["~ty__sunyi"] = "功业未成而身先死，惜哉，惜哉！",
}

General:new(extension, "ty__fengfangnv", "qun", 3, 3, General.Female):addSkills { "tiqi", "baoshu" }
Fk:loadTranslationTable{
  ["ty__fengfangnv"] = "冯妤",
  ["#ty__fengfangnv"] = "泣珠伊人",
  ["illustrator:ty__fengfangnv"] = "君桓文化",

  ["~ty__fengfangnv"] = "诸位，为何如此对我？",
}

local laiyinger = General:new(extension, "laiyinger", "qun", 3, 3, General.Female)
laiyinger:addSkills { "xiaowu", "huaping" }
laiyinger:addRelatedSkill("shawu")
Fk:loadTranslationTable{
  ["laiyinger"] = "来莺儿",
  ["#laiyinger"] = "雀台歌女",
  ["illustrator:laiyinger"] = "君桓文化",

  ["~laiyinger"] = "谷底幽兰艳，芳魂永留香……",
}

General:new(extension, "caohua", "wei", 3, 3, General.Female):addSkills { "caiyi", "guili" }
Fk:loadTranslationTable{
  ["caohua"] = "曹华",
  ["#caohua"] = "殊凰求凤",
  ["designer:caohua"] = "七哀",
  ["illustrator:caohua"] = "HEI-LE",

  ["~caohua"] = "自古忠孝难两全……",
}

--General:new(extension, "zhangfen", "wu", 4):addSkills { "wanglu", "xianzhu", "chaixie" }
Fk:loadTranslationTable{
  ["zhangfen"] = "张奋",
  ["#zhangfen"] = "御驰大攻",
  ["designer:zhangfen"] = "七哀",
  ["illustrator:zhangfen"] = "杨李ping",

  ["~zhangfen"] = "身陨外，愿魂归江东……",
}

General:new(extension, "zhugemengxue", "wei", 3, 3, General.Female):addSkills { "jichun", "hanying" }
Fk:loadTranslationTable{
  ["zhugemengxue"] = "诸葛梦雪",
  ["#zhugemengxue"] = "仙苑停云",
  ["illustrator:zhugemengxue"] = "匠人绘",
  ["designer:zhugemengxue"] = "星移",

  ["~zhugemengxue"] = "雪落青丝上，与君共白头……",
}

General:new(extension, "zhugeruoxue", "wei", 3, 3, General.Female):addSkills { "qiongying", "nuanhui" }
Fk:loadTranslationTable{
  ["zhugeruoxue"] = "诸葛若雪",
  ["#zhugeruoxue"] = "玉榭霑露",
  ["illustrator:zhugeruoxue"] = "匠人绘",
  ["designer:zhugeruoxue"] = "星移",

  ["~zhugeruoxue"] = "自古佳人叹白头……",
}

General:new(extension, "caoxian", "wei", 3, 3, General.Female):addSkills { "lingxi", "zhifou" }
Fk:loadTranslationTable{
  ["caoxian"] = "曹宪",
  ["#caoxian"] = "蝶步韶华",
  ["illustrator:caoxian"] = "君桓文化",
  ["designer:caoxian"] = "快雪时晴",

  ["~caoxian"] = "恨生枭雄府，恨嫁君王家……",
}

General:new(extension, "liutan", "shu", 3, 3, General.Female):addSkills { "jingyin", "chixing" }
Fk:loadTranslationTable{
  ["liutan"] = "柳婒",
  ["#liutan"] = "维情所止",
  ["designer:liutan"] = "韩旭",
  ["illustrator:liutan"] = "黯荧岛",

  ["~liutan"] = "孤灯照长夜，羹熟唤何人？",
}

local wenyuan = General:new(extension, "wenyuan", "shu", 3, 3, General.Female)
wenyuan:addSkills { "kengqiang", "kuichi", "shangjue" }
wenyuan:addRelatedSkill("kunli")
Fk:loadTranslationTable{
  ["wenyuan"] = "文鸳",
  ["#wenyuan"] = "揾泪红袖",
  ["illustrator:wenyuan"] = "匠人绘",
  ["designer:wenyuan"] = "韩旭",

  ["~wenyuan"] = "伯约，回家了。",
}

--笔舌如椽：诸葛恪x 陈琳√ 杨修√ 骆统√ 王昶√ 程秉√ 杨彪√ 阮籍√ 崔琰毛玠√
General:new(extension, "ty__chenlin", "wei", 3):addSkills { "bifa", "ty__songci" }
Fk:loadTranslationTable{
  ["ty__chenlin"] = "陈琳",
  ["#ty__chenlin"] = "破竹之咒",
  ["illustrator:ty__chenlin"] = "Thinking",

  ["$bifa_ty__chenlin1"] = "笔为刀，墨诛心。",
  ["$bifa_ty__chenlin2"] = "文人亦可勇，笔墨用作兵。",
  ["~ty__chenlin"] = "大胆贼人，还不伏诛！",
}

General:new(extension, "ty__yangxiu", "wei", 3):addSkills { "ty__danlao", "ty__jilei" }
Fk:loadTranslationTable{
  ["ty__yangxiu"] = "杨修",
  ["#ty__yangxiu"] = "恃才放旷",
  ["illustrator:ty__yangxiu"] = "alien",

  ["~ty__yangxiu"] = "自作聪明，作茧自缚，悔之晚矣……",
}

General:new(extension, "ty__luotong", "wu", 3):addSkills { "renzheng", "jinjian" }
Fk:loadTranslationTable{
  ["ty__luotong"] = "骆统",
  ["#ty__luotong"] = "蹇谔匪躬",
  ["illustrator:ty__luotong"] = "匠人绘",

  ["~ty__luotong"] = "而立之年，奈何早逝。",
}

General:new(extension, "ty__wangchang", "wei", 3):addSkills { "ty__kaiji", "pingxi" }
Fk:loadTranslationTable{
  ["ty__wangchang"] = "王昶",
  ["#ty__wangchang"] = "攥策及江",
  ["designer:ty__wangchang"] = "韩旭",
  ["illustrator:ty__wangchang"] = "游漫美绘",

  ["~ty__wangchang"] = "志存开济，人亡政息……",
}

General:new(extension, "chengbing", "wu", 3):addSkills { "jingzao", "enyu" }
Fk:loadTranslationTable{
  ["chengbing"] = "程秉",
  ["#chengbing"] = "通达五经",
  ["designer:chengbing"] = "韩旭",
  ["illustrator:chengbing"] = "匠人绘",

  ["~chengbing"] = "著经未成，此憾事也……",
}

General:new(extension, "ty__yangbiao", "qun", 3):addSkills { "ty__zhaohan", "jinjie", "jue" }
Fk:loadTranslationTable{
  ["ty__yangbiao"] = "杨彪",
  ["#ty__yangbiao"] = "德彰海内",
  ["cv:ty__yangbiao"] = "袁国庆",
  ["illustrator:ty__yangbiao"] = "MUMU",

  ["~ty__yangbiao"] = "愧无日磾先见之明，犹怀老牛舐犊之爱……",
}

General:new(extension, "ruanji", "wei", 3):addSkills { "zhaowen", "jiudun" }
Fk:loadTranslationTable{
  ["ruanji"] = "阮籍",
  ["#ruanji"] = "命世大贤",
  ["designer:ruanji"] = "韩旭",
  ["illustrator:ruanji"] = "匠人绘",

  ["~ruanji"] = "诸君，欲与我同醉否？",
}

General:new(extension, "ty__cuiyanmaojie", "wei", 3):addSkills { "ty__zhengbi", "ty__fengying" }
Fk:loadTranslationTable{
  ["ty__cuiyanmaojie"] = "崔琰毛玠",
  ["#ty__cuiyanmaojie"] = "日出月盛",
  ["illustrator:ty__cuiyanmaojie"] = "罔両",

  ["~ty__cuiyanmaojie"] = "为世所痛惜，冤哉！",
}

--钟灵毓秀：董贵人√ 滕芳兰√ 张瑾云√ 周不疑√ 许靖√ 关樾√ 诸葛京√ 刘衿刘佩√
local dongguiren = General:new(extension, "dongguiren", "qun", 3, 3, General.Female)
dongguiren:addSkills { "lianzhi", "lingfang", "fengyingd" }
dongguiren:addRelatedSkill("shouze")
Fk:loadTranslationTable{
  ["dongguiren"] = "董贵人",
  ["#dongguiren"] = "衣雪宫柳",
  ["designer:dongguiren"] = "韩旭",
  ["illustrator:dongguiren"] = "君桓文化",

  ["~dongguiren"] = "陛下乃大汉皇帝，不可言乞！",
}

General:new(extension, "ty__tengfanglan", "wu", 3, 3, General.Female):addSkills { "ty__luochong", "ty__aichen" }
Fk:loadTranslationTable{
  ["ty__tengfanglan"] = "滕芳兰",
  ["#ty__tengfanglan"] = "铃兰零落",
  ["designer:ty__tengfanglan"] = "步穗",
  ["illustrator:ty__tengfanglan"] = "鬼画府",

  ["~ty__tengfanglan"] = "今生缘尽，来世两宽……",
}

General:new(extension, "zhangjinyun", "shu", 3, 3, General.Female):addSkills { "huizhi", "jijiao" }
Fk:loadTranslationTable{
  ["zhangjinyun"] = "张瑾云",
  ["#zhangjinyun"] = "慧秀淑德",
  ["designer:zhangjinyun"] = "韩旭",
  ["illustrator:zhangjinyun"] = "匠人绘",

  ["~zhangjinyun"] = "陛下，妾身来陪你了……",
}

General:new(extension, "zhoubuyi", "wei", 3):addSkills { "shijiz", "silun" }
Fk:loadTranslationTable{
  ["zhoubuyi"] = "周不疑",
  ["#zhoubuyi"] = "幼有异才",
  ["designer:zhoubuyi"] = "拔都沙皇",
  ["illustrator:zhoubuyi"] = "虫师",

  ["~zhoubuyi"] = "人心者，叵测也。",
}

General:new(extension, "ty__xujing", "shu", 3):addSkills { "shangyu", "caixia" }
Fk:loadTranslationTable{
  ["ty__xujing"] = "许靖",
  ["#ty__xujing"] = "璞玉有瑕",
  ["designer:ty__xujing"] = "步穗",
  ["cv:ty__xujing"] = "虞晓旭",
  ["illustrator:ty__xujing"] = "黯荧岛工作室",

  ["~ty__xujing"] = "时人如江鲫，所逐者功利尔……",
}

local guanyue = General:new(extension, "guanyueg", "shu", 4)
guanyue:addSkills { "shouzhi", "fenhui" }
guanyue:addRelatedSkill("xingmen")
Fk:loadTranslationTable{
  ["guanyueg"] = "关樾",
  ["#guanyueg"] = "动心忍性",
  ["designer:guanyueg"] = "韩旭",
  ["illustrator:guanyueg"] = "匠人绘",

  ["~guanyueg"] = "提履无处归，举目山河冷……",
}

local zhugejing = General:new(extension, "zhugejing", "qun", 4)
zhugejing.subkingdom = "jin"
zhugejing:addSkills { "yanzuo", "zuyin", "pijian" }
Fk:loadTranslationTable{
  ["zhugejing"] = "诸葛京",
  ["#zhugejing"] = "武侯遗秀",
  ["designer:zhugejing"] = "月尘",
  ["illustrator:zhugejing"] = "匠人绘",

  ["~zhugejing"] = "子孙不肖，徒遗泪胡尘。",
}

General:new(extension, "liujinliupei", "wei", 3, 3, General.Female):addSkills { "qixinl", "jiusi" }
Fk:loadTranslationTable{
  ["liujinliupei"] = "刘衿刘佩",
  ["#liujinliupei"] = "并蒂连枝",
  ["illustrator:liujinliupei"] = "游卡",

  ["~liujinliupei"] = "阿姊，我冷……/不冷了，不冷了……",
}

return extension
