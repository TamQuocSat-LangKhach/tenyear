local extension = Package:new("tenyear_test")
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_test/skills")

Fk:loadTranslationTable{
  ["tenyear_test"] = "十周年-测试服",
}

General:new(extension, "mu__caiyong", "qun", 3):addSkills { "jiaowei", "ty__feibai" }
Fk:loadTranslationTable{
  ["mu__caiyong"] = "乐蔡邕",
  ["#mu__caiyong"] = "焦尾识音",

  --["~mu__caiyong"] = "",
}

General:new(extension, "chezhou", "wei", 4).hidden = true
Fk:loadTranslationTable{
  ["chezhou"] = "车胄",
  ["#chezhou"] = "当车螳臂",

  ["tmp_illustrate"] = "看画",
  [":tmp_illustrate"] = "这个武将还没上线，你可以看看插画。不会出现在选将框。",

  ["shefuc"] = "慑伏",
  [":shefuc"] = "锁定技，你的牌造成的伤害、其他角色的牌对你造成的伤害均改为X。（X为此牌在手牌中的轮次数）",
  ["pigua"] = "披挂",
  [":pigua"] = "当你对其他角色造成伤害后，若伤害值大于1，你可以获得其至多X张牌（X为轮次数），这些牌于当前回合内不计入手牌上限。",

  --["~chezhou"] = "",
}

General:new(extension, "matie", "qun", 4):addSkills { "sp__zhuiji", "quxian" }
Fk:loadTranslationTable{
  ["matie"] = "马铁",
  ["#matie"] = "继志伏波",

  --["~matie"] = "",
}

General:new(extension, "hansong", "qun", 3):addSkills { "yinbi", "shuaiyan" }
Fk:loadTranslationTable{
  ["hansong"] = "韩嵩",
  ["#hansong"] = "楚国之望",

  --["~hansong"] = "",
}

General:new(extension, "mu__zhugeguo", "shu", 3, 3, General.Female):addSkills { "xidi", "chengyan" }
Fk:loadTranslationTable{
  ["mu__zhugeguo"] = "乐诸葛果",
  --["#mu__zhugeguo"] = "",

  --["~mu__zhugeguo"] = "",
}

General:new(extension, "tystar__wenchou", "qun", 4):addSkills { "lianzhan", "weimingw" }
Fk:loadTranslationTable{
  ["tystar__wenchou"] = "星文丑",
  ["#tystar__wenchou"] = "夔威天下",

  --["~tystar__wenchou"] = "",
}

--General:new(extension, "wm__lukang", "wu", 4):addSkills { "shenduanl", "kegou", "dixian" }
Fk:loadTranslationTable{
  ["wm__lukang"] = "武陆抗",
  ["#wm__lukang"] = "桢武熙朝",

  --["~wm__lukang"] = "",

  ["shenduanl"] = "审断",
  [":shenduanl"] = "当你拼点时，可以弃置一张牌，改为用牌堆中点数最大的一张牌拼点。当一次拼点结算后，你与本次用K拼点的角色各摸一张牌堆中点数最小的牌，然后将赢的角色的拼点牌置于牌堆底。",
  ["kegou"] = "克构",
  [":kegou"] = "出牌阶段限一次，或你使用或打出过牌的其他角色的回合结束时，你可以与一名其他角色拼点，若你赢，你获得牌堆中最小的X个点数的的牌各一张（X为双方拼点牌点数之差，最多为3）；若你没赢，其视为对你使用一张【杀】，然后你可以继续重复此流程。",
  ["dixian"] = "砥贤",
  [":dixian"] = "限定技，出牌阶段，你可以选择一个点数。若牌堆中所有牌均不小于此点数，你摸此点数张牌，你本局游戏使用不大于此点数的牌无距离次数限制；若牌堆中有小于此点数的牌，你获得牌堆和弃牌堆中所有点数为K的牌。",
}

General:new(extension, "tymou__xunyu", "wei", 3):addSkills { "bizuo", "shimou" }
local xunyu2 = General:new(extension, "tymou2__xunyu", "wei", 3)
xunyu2:addSkills { "bizuo", "shimou" }
xunyu2.hidden = true
Fk:loadTranslationTable{
  ["tymou__xunyu"] = "谋荀彧",
  --["#tymou__xunyu"] = "",

  --["~tymou__xunyu"] = "",
  ["tymou2__xunyu"] = "谋荀彧",
  ["#tymou2__xunyu"] = "",
  ["illustrator:tymou2__xunyu"] = "",

  ["$bizuo_tymou2__xunyu1"] = "",
  ["$bizuo_tymou2__xunyu2"] = "",
  ["$shimou_tymou2__xunyu1"] = "",
  ["$shimou_tymou2__xunyu2"] = "",
  ["~tymou2__xunyu"] = "",
}

General:new(extension, "tymou__dongcheng", "qun", 4):addSkills { "baojia", "douwei" }
Fk:loadTranslationTable{
  ["tymou__dongcheng"] = "谋董承",
  --["#tymou__dongcheng"] = "",

  --["~tymou__dongcheng"] = "",
}

General:new(extension, "tymou__caohong", "wei", 4):addSkills { "ty__yingjia", "xianju" }
Fk:loadTranslationTable{
  ["tymou__caohong"] = "谋曹洪",
  --["#tymou__caohong"] = "",

  --["~tymou__caohong"] = "",
}

General:new(extension, "tystar__zhangrang", "qun", 3):addSkills { "duhai", "lingse" }
Fk:loadTranslationTable{
  ["tystar__zhangrang"] = "星张让",
  ["#tystar__zhangrang"] = "斗筲穿窬",

  --["~tystar__zhangrang"] = "",
}

General:new(extension, "tymou__liuxie", "qun", 3):addSkills { "zhanban", "chensheng", "tiancheng" }
Fk:loadTranslationTable{
  ["tymou__liuxie"] = "谋刘协",
  --["#tymou__liuxie"] = "",

  --["~tymou__liuxie"] = "",
}

--General:new(extension, "ty__xiahouxuan", "wei", 3):addSkills { "boxuan", "yizhengx", "guilin" }
Fk:loadTranslationTable{
  ["ty__xiahouxuan"] = "夏侯玄",
  ["#ty__xiahouxuan"] = "玄隐山林",

  --["~ty__xiahouxuan"] = "",

  ["boxuan"] = "博玄",
  [":boxuan"] = "当你使用指定其他角色为目标的手牌结算完毕后，你可以展示牌堆底三张牌，若其中有牌与你使用的牌：<br>"..
  "牌名字数相同，你摸一张牌；<br>花色相同，你可以弃置一名其他角色的一张牌；<br>类别相同，你可以使用一张展示的牌。",
  ["yizhengx"] = "议政",
  [":yizhengx"] = "回合开始时和结束时，你可以与任意名其他角色同时展示一张手牌，若展示的牌类别均相同，你可以将这些牌交给一名角色，否则弃置这些牌，"..
  "你失去1点体力。",
  ["guilin"] = "归林",
  [":guilin"] = "限定技，当你进入濒死状态时，你可以弃置任意张手牌并回复等量体力，然后失去〖议政〗、修改〖博玄〗（可以将使用的牌置于牌堆底）。",
}

General:new(extension, "ty__xiahouhui", "wei", 3, 3, General.Female):addSkills { "dujun", "jikun" }
Fk:loadTranslationTable{
  ["ty__xiahouhui"] = "夏侯徽",
  ["#ty__xiahouhui"] = "雅识有度",

  --["~ty__xiahouhui"] = "",
}

General:new(extension, "zhongyu", "wei", 3):addSkills { "zhidui", "jiesi" }
Fk:loadTranslationTable{
  ["zhongyu"] = "钟毓",
  ["#zhongyu"] = "智辩捷才",

  --["~zhongyu"] = "",
}

return extension
