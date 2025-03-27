local extension = Package:new("tenyear_huicui")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_huicui/skills")

Fk:loadTranslationTable{
  ["tenyear_huicui"] = "十周年-群英荟萃",
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

--诸侯伐董：丁原√ 王荣√ 麹义√ 韩馥
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
  ["designer:hanfu"] = "hanfu",
  ["illustrator:hanfu"] = "福州明暗",

  ["~hanfu"] = "袁本初，你为何不放过我！",
}

--徐州风云：陶谦 曹嵩 张邈 丘力居
--中原狼烟：董承 胡车儿 邹氏 曹安民
--虓虎悲歌：郝萌 严夫人 朱灵 阎柔
--群雄伺动：严白虎x
--文和乱武：李傕 郭汜 樊稠 张济 梁兴 唐姬 段煨 张横 牛辅 董翓 李傕郭汜
--逐鹿天下：张恭 吕凯 卫温诸葛直 卑弥呼
--食禄尽忠：沙摩柯 忙牙长 许贡 张昌蒲
--戚宦之争：张让 何进 何太后 冯方 赵忠 穆顺 伏完
--上兵伐谋：辛毗 伊籍 张温 李肃
--兵临城下：牛金 糜芳傅士仁 李采薇 赵俨 王威 李异谢旌 孙桓 孟达 是仪 孙狼
--千里单骑：魏关羽 杜夫人 秦宜禄 卞喜 胡班 胡金定 关宁
--烽火连天：南华老仙 童渊 张宁 庞德公
--无双上将：潘凤 邢道荣 曹性 淳于琼 夏侯杰 蔡阳 周善
--才子佳人：董白 何晏 孙鲁育 王桃 王悦 赵嫣 滕胤 张嫙 夏侯令女 孙茹 蒯祺 庞山民 张媱 孔融
--芝兰玉树：张虎 吕玲绮 刘永 黄舞蝶 万年公主 滕公主 庞会 赵统赵广 袁尚袁谭袁熙 乐綝 刘理 庞宏
--天下归心：阚泽 魏贾诩 陈登 蔡瑁张允 高览 尹夫人 吕旷吕翔 陈珪 陈矫 秦朗 董昭 侯成 唐咨 臧霸 乐进 曹洪x
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

--代汉涂高：马日磾 张勋 纪灵 雷薄 乐就 桥蕤 董绾 袁胤
--江湖之远：管宁 黄承彦 胡昭 王烈 孟节
--悬壶济世：吉平 孙寒华 郑浑 刘宠骆俊 吴普
--纵横捭阖：陆郁生 祢衡 华歆 荀谌 冯熙 邓芝 宗预 羊祜
--匡鼎炎汉：刘巴 杨仪 黄权 吴班 霍峻 傅肜傅佥 向朗 高翔 李丰 张翼 蒋琬费祎
--太平甲子：管亥 张闿 刘辟 裴元绍 张楚 张曼成
--异军突起：公孙度 孟优 SP孟获 公孙修 马腾
--正音雅乐：蔡文姬 周妃 祢衡 大乔 小乔 邹氏 貂蝉 周瑜
--百战虎贲：兀突骨 文鸯 夏侯霸 皇甫嵩 王双 留赞 雷铜 吴兰 黄祖 陈泰 王濬 杜预 文钦 蒋钦 张任 凌操 吕据 陈武董袭 丁奉
--奇人异士：张宝 司马徽 蒲元 管辂 葛玄 杜夔 朱建平 吴范 赵直 周宣 笮融
--计将安出：程昱 王允 蒋干 刘琦 赵昂 刘晔 杨弘 桓范 郤正 田丰 吕范
--豆蔻梢头：诸葛果 花鬘 辛宪英 薛灵芸 芮姬 段巧笑 田尚衣 柏灵筠 马伶俐 莫琼树 曹媛 灵雎
--皇家贵胄：孙皓 士燮 曹髦 刘辩 刘虞 全惠解 丁尚涴 袁姬 谢灵毓 孙瑜 甘夫人糜夫人 清河公主 曹芳 朱佩兰 卞玥 徐馨 孙霸 甘夫人 糜夫人 卞夫人
--往者可谏：大乔小乔 SP马超 SP赵云 SP甄姬 SP孙策
--章台春望：郭照 樊玉凤 阮瑀 杨婉 潘淑
--锦瑟良缘：曹金玉 孙翊 冯妤 来莺儿 曹华 张奋 诸葛若雪 诸葛梦雪 曹宪 柳婒 文鸳
--笔舌如椽：诸葛恪x 陈琳√ 杨修 骆统 王昶 程秉 杨彪 阮籍 崔琰毛玠√
General:new(extension, "ty__chenlin", "wei", 3):addSkills { "bifa", "ty__songci" }
Fk:loadTranslationTable{
  ["ty__chenlin"] = "陈琳",
  ["#ty__chenlin"] = "破竹之咒",
  ["illustrator:ty__chenlin"] = "Thinking",

  ["$bifa_ty__chenlin1"] = "笔为刀，墨诛心。",
  ["$bifa_ty__chenlin2"] = "文人亦可勇，笔墨用作兵。",
  ["~ty__chenlin"] = "大胆贼人，还不伏诛！",
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
