local extension = Package:new("tenyear_huicui")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_huicui/skills")

Fk:loadTranslationTable{
  ["tenyear_huicui"] = "十周年-群英荟萃",
  ["ty_sp"] = "新服SP",
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

--食禄尽忠：沙摩柯√ 忙牙长√ 许贡 张昌蒲
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

--戚宦之争：张让 何进 何太后 冯方 赵忠 穆顺 伏完
--上兵伐谋：辛毗 伊籍x 张温 李肃
--兵临城下：牛金 糜芳傅士仁 李采薇 赵俨 王威 李异谢旌 孙桓 孟达 是仪 孙狼
--千里单骑：魏关羽 杜夫人 秦宜禄 卞喜 胡班 胡金定 关宁
--烽火连天：南华老仙 童渊 张宁 庞德公
--无双上将：潘凤 邢道荣 曹性 淳于琼 夏侯杰 蔡阳 周善
--才子佳人：董白 何晏 孙鲁育 王桃 王悦 赵嫣 滕胤 张嫙 夏侯令女 孙茹 蒯祺 庞山民 张媱 孔融
--芝兰玉树：张虎 吕玲绮 刘永 黄舞蝶 万年公主 滕公主 庞会 赵统赵广 袁尚袁谭袁熙 乐綝 刘理 庞宏
--天下归心：阚泽 魏贾诩 陈登 蔡瑁张允 高览 尹夫人 吕旷吕翔 陈珪 陈矫 秦朗 董昭 侯成√ 唐咨√ 臧霸√ 乐进√ 曹洪x

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

--代汉涂高：马日磾√ 张勋√ 纪灵√ 雷薄 乐就√ 桥蕤√ 董绾 袁胤√
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

--江湖之远：管宁 黄承彦 胡昭 王烈 孟节
--悬壶济世：吉平 孙寒华 郑浑 刘宠骆俊 吴普
--纵横捭阖：陆郁生 祢衡 华歆 荀谌 冯熙 邓芝 宗预 羊祜
--匡鼎炎汉：刘巴 杨仪 黄权 吴班 霍峻 傅肜傅佥 向朗 高翔 李丰 张翼 蒋琬费祎
--太平甲子：管亥 张闿 刘辟 裴元绍 张楚 张曼成
--异军突起：公孙度 孟优 SP孟获 公孙修 马腾
--正音雅乐：蔡文姬 周妃 祢衡 大乔 小乔 邹氏 貂蝉 周瑜
--百战虎贲：兀突骨 文鸯 夏侯霸 皇甫嵩 王双 留赞 雷铜 吴兰 黄祖 陈泰 王濬 杜预 文钦 蒋钦 张任 凌操 吕据 陈武董袭 丁奉x
--奇人异士：张宝 司马徽 蒲元 管辂 葛玄 杜夔 朱建平 吴范 赵直 周宣 笮融
--计将安出：程昱 王允 蒋干 刘琦 赵昂 刘晔 杨弘 桓范 郤正 田丰 吕范
--豆蔻梢头：诸葛果 花鬘 辛宪英 薛灵芸 芮姬 段巧笑 田尚衣 柏灵筠 马伶俐 莫琼树 曹媛 灵雎
--皇家贵胄：孙皓 士燮 曹髦 刘辩 刘虞 全惠解 丁尚涴 袁姬 谢灵毓 孙瑜 甘夫人糜夫人 清河公主 曹芳 朱佩兰 卞玥 徐馨√ 孙霸√ 甘夫人√ 糜夫人√ 卞夫人x

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

--章台春望：郭照 樊玉凤 阮瑀 杨婉 潘淑
--锦瑟良缘：曹金玉 孙翊 冯妤 来莺儿 曹华 张奋 诸葛若雪√ 诸葛梦雪√ 曹宪√ 柳婒√ 文鸳√
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

--钟灵毓秀：董贵人√ 滕芳兰√ 张瑾云√ 周不疑√ 许靖√ 关樾√ 诸葛京√
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

return extension
