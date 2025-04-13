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

General:new(extension, "ty_ex__xunyou", "wei", 3):addSkills { "qice", "ty_ex__zhiyu" }
Fk:loadTranslationTable{
  ["ty_ex__xunyou"] = "界荀攸",
  ["#ty_ex__xunyou"] = "曹魏的谋主",
  ["illustrator:ty_ex__xunyou"] = "柏桦",

  ["$qice_ty_ex__xunyou1"] = "攸已有妙计在胸，此事不足为虑。",
  ["$qice_ty_ex__xunyou2"] = "主公勿虑，攸有奇策，可解此局。",
  ["~ty_ex__xunyou"] = "再不能替主公出谋了。",
}

General:new(extension, "ty_ex__caozhang", "wei", 4):addSkills { "ty_ex__jiangchi" }
Fk:loadTranslationTable{
  ["ty_ex__caozhang"] = "界曹彰",
  ["#ty_ex__caozhang"] = "黄须儿",
  ["illustrator:ty_ex__caozhang"] = "凝聚永恒",

  ["~ty_ex__caozhang"] = "奈何病薨！",
}

General:new(extension, "ty_ex__wangyi", "wei", 4, 4, General.Female):addSkills { "zhenlie", "miji" }
Fk:loadTranslationTable{
  ["ty_ex__wangyi"] = "界王异",
  ["#ty_ex__wangyi"] = "忠贞礼节",
  ["illustrator:ty_ex__wangyi"] = "夏季和杨杨",

  ["$zhenlie_ty_ex__wangyi1"] = "女子，亦可有坚贞气节！",
  ["$zhenlie_ty_ex__wangyi2"] = "品德端正，心中不移。",
  ["$miji_ty_ex__wangyi1"] = "秘计已成，定助夫君得胜。",
  ["$miji_ty_ex__wangyi2"] = "秘计在此，将军必凯旋而归。",
  ["~ty_ex__wangyi"] = "秘计不成，此城难守……",
}

General:new(extension, "ty_ex__madai", "shu", 4):addSkills { "mashu", "ty_ex__qianxi" }
Fk:loadTranslationTable{
  ["ty_ex__madai"] = "界马岱",
  ["#ty_ex__madai"] = "出其不意",
  ["illustrator:ty_ex__madai"] = "君桓文化",

  ["~ty_ex__madai"] = "丞相临终使命，岱已达成。",
}

General:new(extension, "ty_ex__liaohua", "shu", 4):addSkills { "ty_ex__dangxian", "ty_ex__fuli" }
Fk:loadTranslationTable{
  ["ty_ex__liaohua"] = "界廖化",
  ["#ty_ex__liaohua"] = "历尽沧桑",
  ["illustrator:ty_ex__liaohua"] = "君桓文化",

  ["~ty_ex__liaohua"] = "汉室，气数已尽……",
}

local guanxingzhangbao = General:new(extension, "ty_ex__guanxingzhangbao", "shu", 4)
guanxingzhangbao:addSkills { "ty_ex__fuhun", "ty_ex__tongxin" }
guanxingzhangbao:addRelatedSkills { "ex__wusheng", "ex__paoxiao" }
Fk:loadTranslationTable{
  ["ty_ex__guanxingzhangbao"] = "界关兴张苞",
  ["#ty_ex__guanxingzhangbao"] = "龙兄虎弟",
  ["illustrator:ty_ex__guanxingzhangbao"] = "黯荧岛工作室",

  ["$ex__wusheng_ty_ex__guanxingzhangbao1"] = "青龙驰骋，恍若汉寿再世。",
  ["$ex__wusheng_ty_ex__guanxingzhangbao2"] = "偃月幽光，恰如武圣冲阵。",
  ["$ex__paoxiao_ty_ex__guanxingzhangbao1"] = "桓侯之子，当效父之勇烈！",
  ["$ex__paoxiao_ty_ex__guanxingzhangbao2"] = "蛇矛在手，谁敢与我一战！",
  ["~ty_ex__guanxingzhangbao"] = "马革裹尸，九泉之下无愧见父……",
}

General:new(extension, "ty_ex__chengpu", "wu", 4):addSkills { "ty_ex__lihuo", "ty_ex__chunlao" }
Fk:loadTranslationTable{
  ["ty_ex__chengpu"] = "界程普",
  ["#ty_ex__chengpu"] = "三朝虎臣",
  ["illustrator:ty_ex__chengpu"] = "zoo",

  ["~ty_ex__chengpu"] = "病疠缠身，终天命难违……",
}

General:new(extension, "ty_ex__bulianshi", "wu", 3, 3, General.Female):addSkills { "ty_ex__anxu", "ty_ex__zhuiyi" }
Fk:loadTranslationTable{
  ["ty_ex__bulianshi"] = "界步练师",
  ["#ty_ex__bulianshi"] = "无冕之后",
  ["illustrator:ty_ex__bulianshi"] = "匠人绘",

  ["~ty_ex__bulianshi"] = "还请至尊多保重……",
}

General:new(extension, "ty_ex__handang", "wu", 4):addSkills { "ty_ex__gongqi", "ty_ex__jiefan" }
Fk:loadTranslationTable{
  ["ty_ex__handang"] = "界韩当",
  ["#ty_ex__handang"] = "石城侯",
  ["illustrator:ty_ex__handang"] = "君桓文化",

  ["~ty_ex__handang"] = "三石雕弓今尤在，不见当年挽弓人……",
}

General:new(extension, "ty_ex__liubiao", "qun", 3):addSkills { "ty_ex__zishou", "ty_ex__zongshi" }
Fk:loadTranslationTable{
  ["ty_ex__liubiao"] = "界刘表",
  ["#ty_ex__liubiao"] = "跨蹈汉南",
  ["illustrator:ty_ex__liubiao"] = "聚一",

  ["~ty_ex__liubiao"] = "人心不古！",
}

local zhonghui = General:new(extension, "ty_ex__zhonghui", "wei", 4)
zhonghui:addSkills { "ty_ex__quanji", "ty_ex__zili" }
zhonghui:addRelatedSkills { "ty_ex__paiyi" }
Fk:loadTranslationTable{
  ["ty_ex__zhonghui"] = "界钟会",
  ["#ty_ex__zhonghui"] = "桀骜野心家",
  ["designer:ty_ex__zhonghui"] = "韩旭",
  ["illustrator:ty_ex__zhonghui"] = "君桓文化",

  ["~ty_ex__zhonghui"] = "这就是……自食恶果的下场吗？",
}

General:new(extension, "ty_ex__caochong", "wei", 3):addSkills { "ty_ex__chengxiang", "renxin" }
Fk:loadTranslationTable{
  ["ty_ex__caochong"] = "界曹冲",
  ["#ty_ex__caochong"] = "妙法仁心",
  ["illustrator:ty_ex__caochong"] = "虫师网络",

  ["$renxin_ty_ex__caochong1"] = "见死而不救，非仁者所为。",
  ["$renxin_ty_ex__caochong2"] = "遇难而不援，非我之道也。",
  ["~ty_ex__caochong"] = "父亲，兄长……",
}

General:new(extension, "ty_ex__guohuai", "wei", 4):addSkills { "ty_ex__jingce" }
Fk:loadTranslationTable{
  ["ty_ex__guohuai"] = "界郭淮",
  ["#ty_ex__guohuai"] = "方策精详",
  ["illustrator:ty_ex__guohuai"] = "心中一凛",

  ["~ty_ex__guohuai"] = "岂料姜维……空手接箭！",
}

General:new(extension, "ty_ex__guanping", "shu", 4):addSkills { "ty_ex__jiezhong", "ty_ex__longyin" }
Fk:loadTranslationTable{
  ["ty_ex__guanping"] = "界关平",
  ["#ty_ex__guanping"] = "龙吟九霄",
  ["illustrator:ty_ex__guanping"] = "君桓文化",

  ["~ty_ex__guanping"] = "黄泉路远，儿愿为父亲牵马执鞭……",
}

General:new(extension, "ty_ex__jianyong", "shu", 3):addSkills { "ty_ex__qiaoshui", "zongshij" }
Fk:loadTranslationTable{
  ["ty_ex__jianyong"] = "界简雍",
  ["#ty_ex__jianyong"] = "舌灿莲花",
  ["illustrator:ty_ex__jianyong"] = "黑羽",

  ["$zongshij_ty_ex__jianyong1"] = "能断大事者，不拘小节。",
  ["$zongshij_ty_ex__jianyong2"] = "闲暇自得，威仪不肃。",
  ["~ty_ex__jianyong"] = "此景竟无言以对。",
}

General:new(extension, "ty_ex__liufeng", "shu", 4):addSkills { "ty_ex__xiansi" }
Fk:loadTranslationTable{
  ["ty_ex__liufeng"] = "界刘封",
  ["#ty_ex__liufeng"] = "先主假子",
  ["illustrator:ty_ex__liufeng"] = "JUJU",

  ["~ty_ex__liufeng"] = "父亲，儿实无异心……",
}

General:new(extension, "ty_ex__panzhangmazhong", "wu", 4):addSkills { "ty_ex__duodao", "ty_ex__anjian" }
Fk:loadTranslationTable{
  ["ty_ex__panzhangmazhong"] = "界潘璋马忠",
  ["#ty_ex__panzhangmazhong"] = "夺敌兵刃",
  ["illustrator:ty_ex__panzhangmazhong"] = "青学",

  ["~ty_ex__panzhangmazhong"] = "不知黄雀……在其旁！",
}

General:new(extension, "ty_ex__yufan", "wu", 3):addSkills { "ty_ex__zongxuan", "ty_ex__zhiyan" }
Fk:loadTranslationTable{
  ["ty_ex__yufan"] = "界虞翻",
  ["#ty_ex__yufan"] = "微妙玄通",
  ["illustrator:ty_ex__yufan"] = "君桓文化",

  ["~ty_ex__yufan"] = "若听谏言，何至如此……",
}

General:new(extension, "ty_ex__zhuran", "wu", 4):addSkills { "ty_ex__danshou" }
Fk:loadTranslationTable{
  ["ty_ex__zhuran"] = "界朱然",
  ["#ty_ex__zhuran"] = "胆略无双",
  ["illustrator:ty_ex__zhuran"] = "F.源",

  ["~ty_ex__zhuran"] = "义封一生……不负国家！",
}

General:new(extension, "ty_ex__fuhuanghou", "qun", 3, 3, General.Female):addSkills { "ty_ex__zhuikong", "ty_ex__qiuyuan" }
Fk:loadTranslationTable{
  ["ty_ex__fuhuanghou"] = "界伏皇后",
  ["#ty_ex__fuhuanghou"] = "与世不侵",
  ["illustrator:ty_ex__fuhuanghou"] = "凝聚永恒",

  ["~ty_ex__fuhuanghou"] = "这幽禁之地，好冷……",
}

General:new(extension, "ty_ex__liru", "qun", 3):addSkills { "juece", "ty_ex__mieji", "ty_ex__fencheng" }
Fk:loadTranslationTable{
  ["ty_ex__liru"] = "界李儒",
  ["#ty_ex__liru"] = "决计策士",
  ["illustrator:ty_ex__liru"] = "胖虎饭票",

  ["$juece_ty_ex__liru1"] = "乏谋少计，别做无谓挣扎了！",
  ["$juece_ty_ex__liru2"] = "缺兵少粮，看你还能如何应对？",
  ["~ty_ex__liru"] = "多行不义，必自毙……",
}

General:new(extension, "ty_ex__chenqun", "wei", 3):addSkills { "ty_ex__pindi", "faen" }
Fk:loadTranslationTable{
  ["ty_ex__chenqun"] = "界陈群",
  ["#ty_ex__chenqun"] = "九品中正",
  ["illustrator:ty_ex__chenqun"] = "黯荧岛工作室",

  ["$faen_ty_ex__chenqun1"] = "国法虽严，然不外乎于情。",
  ["$faen_ty_ex__chenqun2"] = "律令如铁，亦有可商榷之处。",
  ["~ty_ex__chenqun"] = "吾身虽亡，然吾志当遗百年……",
}

General:new(extension, "ty_ex__caozhen", "wei", 4):addSkills { "ty_ex__sidi" }
Fk:loadTranslationTable{
  ["ty_ex__caozhen"] = "界曹真",
  ["#ty_ex__caozhen"] = "子丹佳人",
  ["illustrator:ty_ex__caozhen"] = "凝聚永恒",

  ["~ty_ex__caozhen"] = "未竟之业，请你们务必继续！",
}

General:new(extension, "ty_ex__hanhaoshihuan", "wei", 4):addSkills { "ty_ex__shenduan", "ty_ex__yonglue" }
Fk:loadTranslationTable{
  ["ty_ex__hanhaoshihuan"] = "界韩浩史涣",
  ["#ty_ex__hanhaoshihuan"] = "禁卫军",
  ["illustrator:ty_ex__hanhaoshihuan"] = "alien",

  ["~ty_ex__hanhaoshihuan"] = "末将愧对主公知遇之恩！",
}

General:new(extension, "ty_ex__wuyi", "shu", 4):addSkills { "ty_ex__benxi" }
Fk:loadTranslationTable{
  ["ty_ex__wuyi"] = "界吴懿",
  ["#ty_ex__wuyi"] = "奔袭千里",
  ["cv:ty_ex__wuyi"] = "宋国庆",
  ["illustrator:ty_ex__wuyi"] = "青岛磐蒲",

  ["~ty_ex__wuyi"] = "终有疲惫之时！休矣！",
}

General:new(extension, "ty_ex__zhoucang", "shu", 4):addSkills { "ty_ex__zhongyong" }
Fk:loadTranslationTable{
  ["ty_ex__zhoucang"] = "界周仓",
  ["#ty_ex__zhoucang"] = "忠勇当先",
  ["illustrator:ty_ex__zhoucang"] = "君桓文化",

  ["~ty_ex__zhoucang"] = "愿随将军赴死！",
}

General:new(extension, "ty_ex__zhangsong", "shu", 3):addSkills { "qiangzhi", "ty_ex__xiantu" }
Fk:loadTranslationTable{
  ["ty_ex__zhangsong"] = "界张松",
  ["#ty_ex__zhangsong"] = "博学强识",
  ["illustrator:ty_ex__zhangsong"] = "匠人绘",

  ["$qiangzhi_ty_ex__zhangsong1"] = "过目难忘，千载在我腹间。",
  ["$qiangzhi_ty_ex__zhangsong2"] = "吾目为镜，可照世间文字。",
  ["~ty_ex__zhangsong"] = "恨未见使君，入主益州……",
}

General:new(extension, "ty_ex__zhuhuan", "wu", 4):addSkills { "ty_ex__fenli", "ty_ex__pingkou" }
Fk:loadTranslationTable{
  ["ty_ex__zhuhuan"] = "界朱桓",
  ["#ty_ex__zhuhuan"] = "勇烈奋励",
  ["illustrator:ty_ex__zhuhuan"] = "黯荧岛工作室",

  ["~ty_ex__zhuhuan"] = "憾老死病榻，恨未马革裹尸。",
}

General:new(extension, "ty_ex__guyong", "wu", 3):addSkills { "ty_ex__shenxing", "ty_ex__bingyi" }
Fk:loadTranslationTable{
  ["ty_ex__guyong"] = "界顾雍",
  ["#ty_ex__guyong"] = "秉忠如一",
  ["illustrator:ty_ex__guyong"] = "福州明暗",

  ["~ty_ex__guyong"] = "君不可不慎呐！",
}

General:new(extension, "ty_ex__sunluban", "wu", 3, 3, General.Female):addSkills { "ty_ex__zenhui", "ty_ex__jiaojin" }
Fk:loadTranslationTable{
  ["ty_ex__sunluban"] = "界孙鲁班",
  ["#ty_ex__sunluban"] = "谗言毁谤",
  ["cv:ty_ex__sunluban"] = "神隐",
  ["illustrator:ty_ex__sunluban"] = "匠人绘",

  ["~ty_ex__sunluban"] = "谁敢动哀家一根寒毛！",
}

General:new(extension, "ty_ex__caifuren", "qun", 3, 3, General.Female):addSkills { "ty_ex__qieting", "ty_ex__xianzhou" }
Fk:loadTranslationTable{
  ["ty_ex__caifuren"] = "界蔡夫人",
  ["#ty_ex__caifuren"] = "议献荆州",
  ["illustrator:ty_ex__caifuren"] = "合子映画",

  ["~ty_ex__caifuren"] = "枉费妾身机关算尽……",
}

General:new(extension, "ty_ex__jvshou", "qun", 3):addSkills { "ty_ex__jianying", "ty_ex__shibei" }
Fk:loadTranslationTable{
  ["ty_ex__jvshou"] = "界沮授",
  ["#ty_ex__jvshou"] = "徐图渐营",
  ["illustrator:ty_ex__jvshou"] = "鲨鱼嚼嚼",

  ["~ty_ex__jvshou"] = "身处河南，魂归河北……",
}

General:new(extension, "ty_ex__caorui", "wei", 3):addSkills { "huituo", "ty_ex__mingjian", "xingshuai" }
Fk:loadTranslationTable{
  ["ty_ex__caorui"] = "界曹叡",
  ["#ty_ex__caorui"] = "魏明帝",
  ["illustrator:ty_ex__caorui"] = "君桓文化",

  ["$huituo_ty_ex__caorui1"] = "拓土复疆，扬大魏鸿威！",
  ["$huituo_ty_ex__caorui2"] = "制律弘法，固天下社稷！",
  ["$xingshuai_ty_ex__caorui1"] = "家国兴衰，与君共担！",
  ["$xingshuai_ty_ex__caorui2"] = "携君并进，共克此难！",
  ["~ty_ex__caorui"] = "胸有宏图待展，奈何命数已尽……",
}

General:new(extension, "ty_ex__caoxiu", "wei", 4):addSkills { "qianju", "ty_ex__qingxi" }
Fk:loadTranslationTable{
  ["ty_ex__caoxiu"] = "界曹休",
  ["#ty_ex__caoxiu"] = "征东大将军",
  ["cv:ty_ex__caoxiu"] = "清水浊流",
  ["illustrator:ty_ex__caoxiu"] = "写之火工作室",

  ["~ty_ex__caoxiu"] = "奈何痈发背薨！",
}

General:new(extension, "ty_ex__zhongyao", "wei", 3):addSkills { "ty_ex__huomo", "zuoding" }
Fk:loadTranslationTable{
  ["ty_ex__zhongyao"] = "界钟繇",
  ["#ty_ex__zhongyao"] = "定陵侯",
  ["illustrator:ty_ex__zhongyao"] = "匠人绘",

  ["$zuoding_ty_ex__zhongyao1"] = "腹有大才，可助阁下成事。",
  ["$zuoding_ty_ex__zhongyao2"] = "胸有良策，可济将军之危。",
  ["~ty_ex__zhongyao"] = "人有寿终日，笔有墨尽时。",
}

General:new(extension, "ty_ex__liuchen", "shu", 4):addSkills { "ty_ex__zhanjue", "ty_ex__qinwang" }
Fk:loadTranslationTable{
  ["ty_ex__liuchen"] = "界刘谌",
  ["#ty_ex__liuchen"] = "北地王",
  ["illustrator:ty_ex__liuchen"] = "青雨",

  ["~ty_ex__liuchen"] = "儿欲死战，父亲何故先降……",
}

General:new(extension, "ty_ex__xiahoushi", "shu", 3, 3, General.Female):addSkills { "ty_ex__qiaoshi", "ty_ex__yanyu" }
Fk:loadTranslationTable{
  ["ty_ex__xiahoushi"] = "界夏侯氏",
  ["#ty_ex__xiahoushi"] = "燕语呢喃",
  ["illustrator:ty_ex__xiahoushi"] = "匠人绘",

  ["~ty_ex__xiahoushi"] = "天气渐寒，郎君如今安在？",
}

General:new(extension, "ty_ex__zhangyi", "shu", 5):addSkills { "ty_ex__wurong", "ty_ex__shizhi" }
Fk:loadTranslationTable{
  ["ty_ex__zhangyi"] = "界张嶷",
  ["#ty_ex__zhangyi"] = "无当飞军",
  ["illustrator:ty_ex__zhangyi"] = "兴游",

  ["~ty_ex__zhangyi"] = "挥师未捷，杀身以报！",
}

General:new(extension, "ty_ex__quancong", "wu", 4):addSkills { "ty_ex__yaoming" }
Fk:loadTranslationTable{
  ["ty_ex__quancong"] = "界全琮",
  ["#ty_ex__quancong"] = "钱唐侯",
  ["illustrator:ty_ex__quancong"] = "YanBai",

  ["~ty_ex__quancong"] = "邀名射利，内伤骨体，外乏筋肉。",
}

local sunxiu = General:new(extension, "ty_ex__sunxiu", "wu", 3)
sunxiu:addSkills { "ty_ex__yanzhu", "ty_ex__xingxue", "zhaofu" }
sunxiu:addRelatedSkill("ty_ex__yanzhu_update")
Fk:loadTranslationTable{
  ["ty_ex__sunxiu"] = "界孙休",
  ["#ty_ex__sunxiu"] = "兴学重教",
  ["cv:ty_ex__sunxiu"] = "清水浊流",
  ["illustrator:ty_ex__sunxiu"] = "写之火工作室",

  ["~ty_ex__sunxiu"] = "盛世未成，实为憾事！",
}

General:new(extension, "ty_ex__zhuzhi", "wu", 4):addSkills { "ty_ex__anguo" }
Fk:loadTranslationTable{
  ["ty_ex__zhuzhi"] = "界朱治",
  ["#ty_ex__zhuzhi"] = "安国将军",
  ["illustrator:ty_ex__zhuzhi"] = "福州明暗",

  ["~ty_ex__zhuzhi"] = "刀在人在，刀折人亡……",
}

General:new(extension, "ty_ex__gongsunyuan", "qun", 4):addSkills { "ty_ex__huaiyi" }
Fk:loadTranslationTable{
  ["ty_ex__gongsunyuan"] = "界公孙渊",
  ["#ty_ex__gongsunyuan"] = "乐浪公",
  ["illustrator:ty_ex__gongsunyuan"] = "君桓文化",

  ["~ty_ex__gongsunyuan"] = "大星落，君王死……",
}

General:new(extension, "ty_ex__guotupangji", "qun", 3):addSkills { "ty_ex__jigong", "shifei" }
Fk:loadTranslationTable{
  ["ty_ex__guotupangji"] = "界郭图逄纪",
  ["#ty_ex__guotupangji"] = "急攻猛进",
  ["illustrator:ty_ex__guotupangji"] = "磐蒲",

  ["$shifei_ty_ex__guotupangji1"] = "若依吾计而行，许昌旦夕可破！",
  ["$shifei_ty_ex__guotupangji2"] = "先锋怯战，非谋策之过。",
  ["~ty_ex__guotupangji"] = "主公，我还有一计啊！",
}

return extension
